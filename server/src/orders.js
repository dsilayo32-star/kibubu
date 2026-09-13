'use strict';

const { getFirestore, serverTimestamp } = require('./firebase');

const COLLECTION = 'mpesaOrders';

const STATUS = Object.freeze({
  PENDING: 'PENDING',
  PAID: 'PAID',
  FAILED: 'FAILED',
});

/**
 * Creates a PENDING order document for a freshly-initiated STK Push.
 * Firestore write failures are swallowed (logged) so a DB hiccup never breaks
 * the client-facing STK response.
 */
async function createPendingOrder({ checkoutRequestId, phoneNumber, amount, accountReference, merchantRequestId }) {
  const db = getFirestore();
  if (!db) return;

  try {
    await db.collection(COLLECTION).doc(checkoutRequestId).set({
      status: STATUS.PENDING,
      phoneNumber,
      amount: Number(amount),
      accountReference,
      merchantRequestId: merchantRequestId ?? null,
      createdAt: serverTimestamp(),
    });
  } catch (dbError) {
    console.warn('[Firebase] Skipping DB write - error writing to Firestore:', dbError.message);
  }
}

/**
 * Applies a Safaricom callback result to an existing order.
 * Returns one of: 'ignored' (unknown checkout), 'updated', or 'skipped' (no DB).
 */
async function applyCallbackResult(callbackData) {
  const db = getFirestore();
  if (!db) return 'skipped';

  const orderRef = db.collection(COLLECTION).doc(callbackData.CheckoutRequestID);
  const orderSnapshot = await orderRef.get();
  if (!orderSnapshot.exists) {
    console.warn(`Ignoring callback for unknown checkout: ${callbackData.CheckoutRequestID}`);
    return 'ignored';
  }

  if (callbackData.ResultCode === 0) {
    const metadata = extractCallbackMetadata(callbackData);
    await orderRef.set({
      status: STATUS.PAID,
      amount: metadata.Amount ?? null,
      mpesaReceiptNumber: metadata.MpesaReceiptNumber ?? null,
      phoneNumber: metadata.PhoneNumber ?? null,
      resultCode: callbackData.ResultCode,
      resultDesc: callbackData.ResultDesc ?? null,
      paidAt: serverTimestamp(),
    }, { merge: true });
  } else {
    await orderRef.set({
      status: STATUS.FAILED,
      resultCode: callbackData.ResultCode,
      resultDesc: callbackData.ResultDesc ?? 'Payment failed',
      failedAt: serverTimestamp(),
    }, { merge: true });
  }

  return 'updated';
}

/**
 * Reads the current state of an STK order, shaped for a compact JSON response.
 * Returns null when the order is unknown or Firestore is unavailable.
 */
async function getOrderStatus(checkoutRequestId) {
  const db = getFirestore();
  if (!db) return null;

  try {
    const snapshot = await db.collection(COLLECTION).doc(checkoutRequestId).get();
    if (!snapshot.exists) return null;

    const data = snapshot.data() || {};
    return {
      checkoutRequestId,
      status: data.status ?? STATUS.PENDING,
      amount: data.amount ?? null,
      phoneNumber: data.phoneNumber ?? null,
      accountReference: data.accountReference ?? null,
      mpesaReceiptNumber: data.mpesaReceiptNumber ?? null,
      resultCode: data.resultCode ?? null,
      resultDesc: data.resultDesc ?? null,
    };
  } catch (error) {
    console.warn('[Firebase] Could not read order status:', error.message);
    return null;
  }
}

/**
 * Flattens Daraja's CallbackMetadata.Item[] into a plain { Name: Value } map.
 */
function extractCallbackMetadata(callbackData) {
  const items = callbackData.CallbackMetadata?.Item ?? [];
  return Object.fromEntries(items.map((item) => [item.Name, item.Value]));
}

module.exports = {
  COLLECTION,
  STATUS,
  createPendingOrder,
  applyCallbackResult,
  getOrderStatus,
  extractCallbackMetadata,
};
