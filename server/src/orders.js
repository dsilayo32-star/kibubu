'use strict';

const firebase = require('./firebase');

const COLLECTION = 'mpesaOrders';

const STATUS = Object.freeze({
  PENDING: 'PENDING',
  PAID: 'COMPLETED',
  COMPLETED: 'COMPLETED',
  FAILED: 'FAILED',
});

/**
 * Creates a PENDING order document for a freshly-initiated STK Push.
 * Firestore write failures are swallowed (logged) so a DB hiccup never breaks
 * the client-facing STK response.
 */
async function createPendingOrder({ checkoutRequestId, phoneNumber, amount, accountReference, merchantRequestId }) {
  const db = firebase.getFirestore();
  if (!db) return;

  try {
    await db.collection(COLLECTION).doc(checkoutRequestId).set({
      status: STATUS.PENDING,
      phoneNumber,
      amount: Number(amount),
      accountReference,
      merchantRequestId: merchantRequestId ?? null,
      createdAt: firebase.serverTimestamp(),
    });
  } catch (dbError) {
    console.warn('[Firebase] Skipping DB write - error writing to Firestore:', dbError.message);
  }
}

/**
 * Applies a callback result (from Safaricom or Vodacom) to an existing order.
 * Returns one of: 'ignored' (unknown checkout), 'updated', or 'skipped' (no DB).
 */
async function applyCallbackResult(callbackData) {
  const db = firebase.getFirestore();
  if (!db) return 'skipped';

  const checkoutRequestId = callbackData.CheckoutRequestID;
  if (!checkoutRequestId) return 'ignored';

  const orderRef = db.collection(COLLECTION).doc(checkoutRequestId);
  const orderSnapshot = await orderRef.get();
  if (!orderSnapshot.exists) {
    console.warn(`Ignoring callback for unknown checkout: ${checkoutRequestId}`);
    return 'ignored';
  }

  const isSuccess =
    callbackData.ResultCode === 0 ||
    callbackData.ResultCode === '0' ||
    callbackData.output_ResponseCode === 'INS-0';

  if (isSuccess) {
    const metadata = extractCallbackMetadata(callbackData);
    await orderRef.set({
      status: STATUS.COMPLETED,
      amount: metadata.Amount ?? callbackData.amount ?? callbackData.output_Amount ?? null,
      mpesaReceiptNumber:
        metadata.MpesaReceiptNumber ??
        callbackData.output_TransactionID ??
        callbackData.MpesaReceiptNumber ??
        null,
      phoneNumber: metadata.PhoneNumber ?? callbackData.phoneNumber ?? null,
      resultCode: callbackData.ResultCode ?? callbackData.output_ResponseCode ?? 0,
      resultDesc:
        callbackData.ResultDesc ??
        callbackData.output_ResponseDesc ??
        'Transaction completed successfully',
      paidAt: firebase.serverTimestamp(),
    }, { merge: true });
  } else {
    await orderRef.set({
      status: STATUS.FAILED,
      resultCode: callbackData.ResultCode ?? callbackData.output_ResponseCode ?? 1,
      resultDesc:
        callbackData.ResultDesc ??
        callbackData.output_ResponseDesc ??
        'Payment failed',
      failedAt: firebase.serverTimestamp(),
    }, { merge: true });
  }

  return 'updated';
}

/**
 * Applies Vodacom OpenAPI webhook / callback specifically.
 */
async function applyVodacomCallbackResult(vodacomData) {
  const checkoutRequestId =
    vodacomData.CheckoutRequestID ||
    vodacomData.output_ConversationID ||
    vodacomData.output_ThirdPartyConversationID;

  return applyCallbackResult({
    CheckoutRequestID: checkoutRequestId,
    output_ResponseCode: vodacomData.output_ResponseCode,
    output_ResponseDesc: vodacomData.output_ResponseDesc,
    output_TransactionID: vodacomData.output_TransactionID,
    amount: vodacomData.input_Amount || vodacomData.output_Amount,
  });
}

/**
 * Reads the current state of an STK order, shaped for a compact JSON response.
 * Returns null when the order is unknown or Firestore is unavailable.
 */
async function getOrderStatus(checkoutRequestId) {
  const db = firebase.getFirestore();
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
  applyVodacomCallbackResult,
  getOrderStatus,
  extractCallbackMetadata,
};
