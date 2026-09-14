'use strict';

const express = require('express');
const {
  MAX_AMOUNT,
  normalizePhone,
  detectCountryCode,
  resolveDarajaPhoneNumber,
  positiveAmount,
  safeReference,
} = require('./validation');
const { initiateStkPush, extractDarajaError } = require('./daraja');
const { initiateVodacomPayment, extractVodacomError } = require('./vodacom');
const {
  createPendingOrder,
  applyCallbackResult,
  applyVodacomCallbackResult,
  getOrderStatus,
} = require('./orders');

const router = express.Router();

const ACCEPTED = { ResultCode: 0, ResultDesc: 'Accepted' };
const INVALID_CALLBACK = { ResultCode: 1, ResultDesc: 'Invalid callback' };

// Accepted phone-number shapes for the error message.
function phoneErrorMessage() {
  return 'phoneNumber lazima iwe namba ya Tanzania (255...) au Kenya (254...) kwa ajili ya majaribio.';
}
// (helper above is reused by validateStkRequest below)

/**
 * Validates the STK request body. Returns { ok: true, phoneNumber, amount,
 * accountReference } on success, or { ok: false, status, body } describing the
 * 400 response to send.
 */
function validateStkRequest(body) {
  const phoneNumber = normalizePhone(body?.phoneNumber);
  const amount = body?.amount;
  const accountReference = safeReference(body?.accountReference);

  if (!phoneNumber) {
    const body400 = { error: phoneErrorMessage() };
    return { ok: false, status: 400, body: body400 };
  }
  if (!positiveAmount(amount)) {
    return { ok: false, status: 400, body: { error: `amount must be a positive integer up to ${MAX_AMOUNT}.` } };
  }
  if (!accountReference) {
    return { ok: false, status: 400, body: { error: 'accountReference contains invalid characters.' } };
  }

  return { ok: true, phoneNumber, amount, accountReference };
}

// --- Service/routing info endpoints -----------------------------------------

router.get('/api/status', (_req, res) => res.json({
  status: 'running',
  service: 'kibubu-mpesa-server',
  health: '/health',
  timestamp: new Date().toISOString(),
}));

router.get('/health', (_req, res) => res.json({ ok: true }));

// --- Hali ya oda (kwa kurudisha matokeo ya callback kwenye dashboard) --------

router.get('/api/v1/order-status', async (req, res) => {
  const checkoutRequestId = String(req.query.checkoutRequestId ?? '').trim();
  if (!checkoutRequestId) {
    return res.status(400).json({ error: 'checkoutRequestId is required.' });
  }

  const order = await getOrderStatus(checkoutRequestId);
  if (!order) {
    return res.status(404).json({ error: 'Order not found.', checkoutRequestId });
  }

  return res.json(order);
});

// --- Dynamic STK / Mobile Money Router --------------------------------------

/**
 * Routes payment request dynamically based on country code:
 * - 254: Safaricom Daraja API (Kenya)
 * - 255: Vodacom Tanzania M-Pesa OpenAPI (Tanzania)
 */
async function processDynamicPayment({ phoneNumber, amount, accountReference }) {
  const countryCode = detectCountryCode(phoneNumber);

  if (countryCode === '255') {
    // Tanzania: Vodacom OpenAPI
    const result = await initiateVodacomPayment({
      phoneNumber,
      amount,
      accountReference,
    });
    return { provider: 'vodacom', result };
  } else {
    // Kenya (+254) or fallback: Safaricom Daraja
    const darajaPartyPhone = resolveDarajaPhoneNumber(phoneNumber);
    const result = await initiateStkPush({
      darajaPartyPhone,
      amount,
      accountReference,
      phoneNumber,
    });
    return { provider: 'daraja', result };
  }
}

// --- STK Push ----------------------------------------------------------------

router.post('/api/dashboard/test-stk', async (req, res) => {
  const validation = validateStkRequest(req.body);
  if (!validation.ok) {
    return res.status(validation.status).json(validation.body);
  }

  const { phoneNumber, amount, accountReference } = validation;

  try {
    const { provider, result } = await processDynamicPayment({ phoneNumber, amount, accountReference });

    if (result.CheckoutRequestID) {
      await createPendingOrder({
        checkoutRequestId: result.CheckoutRequestID,
        phoneNumber,
        amount,
        accountReference,
        merchantRequestId: result.MerchantRequestID,
      });
    }

    return res.status(200).json({
      ...result,
      provider,
    });
  } catch (error) {
    const isVodacom = detectCountryCode(phoneNumber) === '255';
    const { status, data, darajaData, message } = isVodacom
      ? extractVodacomError(error)
      : extractDarajaError(error);

    return res.status(status).json({
      error: message,
      details: data || darajaData || null,
      provider: isVodacom ? 'vodacom' : 'daraja',
    });
  }
});

router.post('/api/v1/stkpush', async (req, res) => {
  const validation = validateStkRequest(req.body);
  if (!validation.ok) {
    return res.status(validation.status).json(validation.body);
  }

  const { phoneNumber, amount, accountReference } = validation;

  try {
    const { provider, result } = await processDynamicPayment({ phoneNumber, amount, accountReference });

    if (result.CheckoutRequestID) {
      await createPendingOrder({
        checkoutRequestId: result.CheckoutRequestID,
        phoneNumber,
        amount,
        accountReference,
        merchantRequestId: result.MerchantRequestID,
      });
    }

    return res.status(200).json({
      ...result,
      provider,
    });
  } catch (error) {
    const isVodacom = detectCountryCode(phoneNumber) === '255';
    const { status, data, darajaData, message } = isVodacom
      ? extractVodacomError(error)
      : extractDarajaError(error);

    console.error(`[Payment Error - ${isVodacom ? 'Vodacom' : 'Daraja'}] Details:`, {
      status,
      message,
      response: data || darajaData,
    });

    return res.status(status).json({
      error: message,
      details: data || darajaData || null,
      errorCode: data?.output_ResponseCode || darajaData?.errorCode || null,
      requestId: data?.output_ConversationID || darajaData?.requestId || null,
      provider: isVodacom ? 'vodacom' : 'daraja',
    });
  }
});

// --- Webhook / Callback Handler (Safaricom & Vodacom) ------------------------

/**
 * Universal callback endpoint: handles webhooks from Safaricom Daraja or Vodacom OpenAPI.
 */
router.post(['/api/v1/mpesa-callback', '/api/v1/vodacom-callback'], async (req, res) => {
  const body = req.body || {};

  // 1. Detect if it's Safaricom Daraja format
  // Payload: { Body: { stkCallback: { CheckoutRequestID, ResultCode, CallbackMetadata: ... } } }
  if (body.Body?.stkCallback) {
    const callbackData = body.Body.stkCallback;
    if (!callbackData?.CheckoutRequestID) {
      return res.status(400).json(INVALID_CALLBACK);
    }

    try {
      await applyCallbackResult(callbackData);
    } catch (error) {
      console.error('[Daraja Callback Error]:', error.message);
    }

    return res.status(200).json(ACCEPTED);
  }

  // 2. Detect if it's Vodacom OpenAPI format
  // Payload has output_ResponseCode or output_TransactionID or output_ConversationID
  if (
    body.output_ResponseCode !== undefined ||
    body.output_TransactionID !== undefined ||
    body.output_ConversationID !== undefined ||
    body.output_ThirdPartyConversationID !== undefined
  ) {
    const checkoutRequestId =
      body.CheckoutRequestID ||
      body.output_ConversationID ||
      body.output_ThirdPartyConversationID;

    if (!checkoutRequestId) {
      return res.status(400).json({
        output_ResponseCode: 'INS-1',
        output_ResponseDesc: 'Missing CheckoutRequestID / ConversationID',
      });
    }

    try {
      await applyVodacomCallbackResult(body);
    } catch (error) {
      console.error('[Vodacom Callback Error]:', error.message);
    }

    return res.status(200).json({
      output_ResponseCode: 'INS-0',
      output_ResponseDesc: 'Request processed successfully',
      ResultCode: 0,
      ResultDesc: 'Accepted',
    });
  }

  // 3. Fallback generic callback format (e.g., testing or direct CheckoutRequestID post)
  if (body.CheckoutRequestID) {
    try {
      await applyCallbackResult(body);
    } catch (error) {
      console.error('[Generic Callback Error]:', error.message);
    }
    return res.status(200).json(ACCEPTED);
  }

  return res.status(400).json(INVALID_CALLBACK);
});

module.exports = { router, validateStkRequest, phoneErrorMessage, ACCEPTED, INVALID_CALLBACK };
