'use strict';

const express = require('express');
const {
  MAX_AMOUNT,
  normalizePhone,
  resolveDarajaPhoneNumber,
  positiveAmount,
  safeReference,
} = require('./validation');
const { initiateStkPush, extractDarajaError } = require('./daraja');
const {
  createPendingOrder,
  applyCallbackResult,
  getOrderStatus,
} = require('./orders');

const router = express.Router();

const ACCEPTED = { ResultCode: 0, ResultDesc: 'Accepted' };
const INVALID_CALLBACK = { ResultCode: 1, ResultDesc: 'Invalid callback' };

// Accepted phone-number shapes for the error message.
function phoneErrorMessage() {
  return 'phoneNumber must be a Tanzanian number: 2557XXXXXXXX (or 07XXXXXXXX).';
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

// --- STK Push ----------------------------------------------------------------

router.post('/api/v1/stkpush', async (req, res) => {
  const validation = validateStkRequest(req.body);
  if (!validation.ok) {
    return res.status(validation.status).json(validation.body);
  }

  const { phoneNumber, amount, accountReference } = validation;

  // Namba ya Tanzania (255XXXXXXXXX) inatumwa kwa Daraja kama ilivyo.
  const darajaPartyPhone = resolveDarajaPhoneNumber(phoneNumber);

  try {
    const result = await initiateStkPush({ darajaPartyPhone, amount, accountReference, phoneNumber });

    if (result.CheckoutRequestID) {
      await createPendingOrder({
        checkoutRequestId: result.CheckoutRequestID,
        phoneNumber,
        amount,
        accountReference,
        merchantRequestId: result.MerchantRequestID,
      });
    }

    return res.status(200).json(result);
  } catch (error) {
    const { status, darajaData, message } = extractDarajaError(error);
    console.error('[STK Push Error] Details:', { status, message, darajaResponse: darajaData });

    return res.status(status).json({
      error: message,
      details: darajaData || null,
      errorCode: darajaData?.errorCode || null,
      requestId: darajaData?.requestId || null,
    });
  }
});

// --- Safaricom callback ------------------------------------------------------

router.post('/api/v1/mpesa-callback', async (req, res) => {
  const callbackData = req.body?.Body?.stkCallback;

  if (!callbackData?.CheckoutRequestID) {
    return res.status(400).json(INVALID_CALLBACK);
  }

  try {
    await applyCallbackResult(callbackData);
  } catch (error) {
    console.error('M-Pesa callback error:', error.message);
  }

  // Daraja expects a 200 "Accepted" acknowledgement even after internal errors.
  return res.status(200).json(ACCEPTED);
});

module.exports = { router, validateStkRequest, phoneErrorMessage, ACCEPTED, INVALID_CALLBACK };
