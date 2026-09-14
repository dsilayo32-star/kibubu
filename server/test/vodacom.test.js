'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { encryptVodacomKey, initiateVodacomPayment, extractVodacomError } = require('../src/vodacom');
const { getVodacomConfig } = require('../src/config');

test('getVodacomConfig returns defaults and mock mode when keys not configured', () => {
  const config = getVodacomConfig({});
  assert.equal(config.isMock, true);
  assert.equal(config.serviceProviderCode, '000000');
  assert.ok(config.baseUrl.includes('vodacomTZN'));
});

test('initiateVodacomPayment completes in mock mode when credentials unset', async () => {
  const res = await initiateVodacomPayment({
    phoneNumber: '255712345678',
    amount: 1000,
    accountReference: 'KIBUBU_TZ_TEST',
  });

  assert.equal(res.output_ResponseCode, 'INS-0');
  assert.ok(res.output_ConversationID);
  assert.ok(res.output_TransactionID);
  assert.equal(res.CheckoutRequestID, res.output_ConversationID);
  assert.equal(res.ResponseCode, '0');
  assert.equal(res.provider, 'vodacom');
});

test('extractVodacomError normalizes error structures', () => {
  const err1 = new Error('Network error');
  const normalized1 = extractVodacomError(err1);
  assert.equal(normalized1.status, 500);
  assert.equal(normalized1.message, 'Network error');

  const err2 = {
    response: {
      status: 400,
      data: {
        output_ResponseCode: 'INS-14',
        output_ResponseDesc: 'Invalid phone number',
      },
    },
  };
  const normalized2 = extractVodacomError(err2);
  assert.equal(normalized2.status, 400);
  assert.equal(normalized2.message, 'Invalid phone number');
});

test('encryptVodacomKey correctly formats and encrypts with a valid RSA public key', () => {
  const { generateKeyPairSync } = require('crypto');
  const { publicKey } = generateKeyPairSync('rsa', {
    modulusLength: 2048,
    publicKeyEncoding: { type: 'spki', format: 'pem' },
  });

  const base64Key = publicKey
    .replace(/-----BEGIN PUBLIC KEY-----/g, '')
    .replace(/-----END PUBLIC KEY-----/g, '')
    .replace(/[\r\n\s]/g, '');

  const encrypted = encryptVodacomKey('test_api_key', base64Key);
  assert.ok(typeof encrypted === 'string');
  assert.ok(encrypted.length > 50);
});
