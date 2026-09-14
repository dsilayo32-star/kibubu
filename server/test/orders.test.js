const test = require('node:test');
const assert = require('node:assert/strict');
const { extractCallbackMetadata, getOrderStatus, STATUS } = require('../src/orders');

test('extractCallbackMetadata flattens Daraja CallbackMetadata.Item[]', () => {
  const metadata = extractCallbackMetadata({
    CallbackMetadata: {
      Item: [
        { Name: 'Amount', Value: 1000 },
        { Name: 'MpesaReceiptNumber', Value: 'QK12ABC34' },
        { Name: 'PhoneNumber', Value: 255754123456 },
      ],
    },
  });

  assert.deepEqual(metadata, {
    Amount: 1000,
    MpesaReceiptNumber: 'QK12ABC34',
    PhoneNumber: 255754123456,
  });
});

test('extractCallbackMetadata returns an empty map when metadata is missing', () => {
  assert.deepEqual(extractCallbackMetadata({}), {});
  assert.deepEqual(extractCallbackMetadata({ CallbackMetadata: {} }), {});
});

test('STATUS exposes the order states', () => {
  assert.equal(STATUS.PENDING, 'PENDING');
  assert.equal(STATUS.COMPLETED, 'COMPLETED');
  assert.equal(STATUS.FAILED, 'FAILED');
});

test('getOrderStatus returns null when Firestore is not configured', async () => {
  // Bila firebase-admin.json, hakuna DB — endpoint hairipoti kosa la 500.
  assert.equal(await getOrderStatus('ws_CO_123'), null);
});


test('applyCallbackResult handles Safaricom and Vodacom success and failure without throwing', async () => {
  const { applyCallbackResult, applyVodacomCallbackResult } = require('../src/orders');
  // Without Firestore, should return 'skipped'
  const r1 = await applyCallbackResult({
    CheckoutRequestID: 'test_checkout_123',
    ResultCode: 0,
    CallbackMetadata: { Item: [{ Name: 'Amount', Value: 1000 }] },
  });
  assert.equal(r1, 'skipped');

  const r2 = await applyVodacomCallbackResult({
    output_ConversationID: 'vod_conv_123',
    output_ResponseCode: 'INS-0',
    output_TransactionID: 'TXN123',
    output_ResponseDesc: 'Success',
  });
  assert.equal(r2, 'skipped');
});


test('applyCallbackResult updates order to COMPLETED for successful Safaricom Daraja callback', async () => {
  const firebase = require('../src/firebase');
  let savedData = null;
  const mockDb = {
    collection: () => ({
      doc: () => ({
        get: async () => ({ exists: true }),
        set: async (data) => { savedData = data; },
      }),
    }),
  };
  const originalGetFirestore = firebase.getFirestore;
  firebase.getFirestore = () => mockDb;

  try {
    const { applyCallbackResult } = require('../src/orders');
    const res = await applyCallbackResult({
      CheckoutRequestID: 'ws_CO_TEST',
      ResultCode: 0,
      ResultDesc: 'Success',
      CallbackMetadata: {
        Item: [
          { Name: 'Amount', Value: 2500 },
          { Name: 'MpesaReceiptNumber', Value: 'QWERT123' },
          { Name: 'PhoneNumber', Value: 254708374149 },
        ],
      },
    });

    assert.equal(res, 'updated');
    assert.equal(savedData.status, 'COMPLETED');
    assert.equal(savedData.amount, 2500);
    assert.equal(savedData.mpesaReceiptNumber, 'QWERT123');
    assert.equal(savedData.resultCode, 0);
  } finally {
    firebase.getFirestore = originalGetFirestore;
  }
});

test('applyVodacomCallbackResult updates order to COMPLETED for successful Vodacom callback', async () => {
  const firebase = require('../src/firebase');
  let savedData = null;
  const mockDb = {
    collection: () => ({
      doc: () => ({
        get: async () => ({ exists: true }),
        set: async (data) => { savedData = data; },
      }),
    }),
  };
  const originalGetFirestore = firebase.getFirestore;
  firebase.getFirestore = () => mockDb;

  try {
    const { applyVodacomCallbackResult } = require('../src/orders');
    const res = await applyVodacomCallbackResult({
      output_ConversationID: 'VOD_CONV_999',
      output_ResponseCode: 'INS-0',
      output_ResponseDesc: 'Request processed successfully',
      output_TransactionID: 'TXN_TZ_555',
      output_Amount: 10000,
    });

    assert.equal(res, 'updated');
    assert.equal(savedData.status, 'COMPLETED');
    assert.equal(savedData.amount, 10000);
    assert.equal(savedData.mpesaReceiptNumber, 'TXN_TZ_555');
  } finally {
    firebase.getFirestore = originalGetFirestore;
  }
});

test('applyCallbackResult updates order to FAILED when transaction fails', async () => {
  const firebase = require('../src/firebase');
  let savedData = null;
  const mockDb = {
    collection: () => ({
      doc: () => ({
        get: async () => ({ exists: true }),
        set: async (data) => { savedData = data; },
      }),
    }),
  };
  const originalGetFirestore = firebase.getFirestore;
  firebase.getFirestore = () => mockDb;

  try {
    const { applyCallbackResult } = require('../src/orders');
    const res = await applyCallbackResult({
      CheckoutRequestID: 'ws_CO_FAIL',
      ResultCode: 1032,
      ResultDesc: 'Request cancelled by user',
    });

    assert.equal(res, 'updated');
    assert.equal(savedData.status, 'FAILED');
    assert.equal(savedData.resultCode, 1032);
  } finally {
    firebase.getFirestore = originalGetFirestore;
  }
});
