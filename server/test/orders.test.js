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

test('STATUS exposes the three order states', () => {
  assert.equal(STATUS.PENDING, 'PENDING');
  assert.equal(STATUS.PAID, 'PAID');
  assert.equal(STATUS.FAILED, 'FAILED');
});

test('getOrderStatus returns null when Firestore is not configured', async () => {
  // Bila firebase-admin.json, hakuna DB — endpoint hairipoti kosa la 500.
  assert.equal(await getOrderStatus('ws_CO_123'), null);
});
