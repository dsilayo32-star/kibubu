'use strict';

const express = require('express');
const {
  normalizePhone,
  resolveDarajaPhoneNumber,
  positiveAmount,
  safeReference,
} = require('./validation');
const { isSandbox } = require('./config');
const { initiateStkPush, extractDarajaError } = require('./daraja');
const { createPendingOrder, applyCallbackResult } = require('./orders');

const router = express.Router();

const ACCEPTED = { ResultCode: 0, ResultDesc: 'Accepted' };
const INVALID_CALLBACK = { ResultCode: 1, ResultDesc: 'Invalid callback' };

// Accepted phone-number shapes for the error message, per environment.
function phoneErrorMessage(sandbox) {
  return sandbox
    ? 'phoneNumber must be 2557XXXXXXXX or test format 2547XXXXXXXX.'
    : 'phoneNumber must be 2557XXXXXXXX.';
}

/**
 * Validates the STK request body. Returns { ok: true, phoneNumber, amount,
 * accountReference } on success, or { ok: false, status, body } describing the
 * 400 response to send.
 */
function validateStkRequest(body, sandbox) {
  const phoneNumber = normalizePhone(body?.phoneNumber, sandbox);
  const amount = body?.amount;
  const accountReference = safeReference(body?.accountReference);

  if (!phoneNumber) {
    return { ok: false, status: 400, body: { error: phoneErrorMessage(sandbox) } };
  }
  if (!positiveAmount(amount)) {
    return { ok: false, status: 400, body: { error: 'amount must be a positive integer up to 150000.' } };
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

// --- STK Push ----------------------------------------------------------------

router.post('/api/v1/stkpush', async (req, res) => {
  const sandbox = isSandbox();

  const validation = validateStkRequest(req.body, sandbox);
  if (!validation.ok) {
    return res.status(validation.status).json(validation.body);
  }

  const { phoneNumber, amount, accountReference } = validation;

  // In Daraja Sandbox, Tanzanian numbers (255...) return 400.002.02 Invalid
  // PhoneNumber. Substitute 255 numbers with the Daraja Sandbox test number in
  // sandbox mode, while preserving the original number in logs and production.
  const darajaPartyPhone = resolveDarajaPhoneNumber(phoneNumber, sandbox);

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
