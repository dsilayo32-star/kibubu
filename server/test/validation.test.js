const test = require('node:test');
const assert = require('node:assert/strict');
const {
  MAX_AMOUNT,
  normalizePhone,
  detectCountryCode,
  resolveDarajaPhoneNumber,
  positiveAmount,
  safeReference,
} = require('../src/validation');

test('normalizes accepted Tanzanian mobile formats to 2557XXXXXXXX', () => {
  assert.equal(normalizePhone('0712 345 678'), '255712345678');
  assert.equal(normalizePhone('+255712345678'), '255712345678');
  assert.equal(normalizePhone('255712345678'), '255712345678');
});

test('normalizes accepted Kenyan mobile formats to 254XXXXXXXXX', () => {
  assert.equal(normalizePhone('0712345678'), '255712345678'); // Tanzanian 07 prefix takes priority
  assert.equal(normalizePhone('0112345678'), '254112345678'); // Kenyan 01 prefix
  assert.equal(normalizePhone('+254712345678'), '254712345678');
  assert.equal(normalizePhone('254712345678'), '254712345678');
  assert.equal(normalizePhone('254708374149'), '254708374149');
});

test('detectCountryCode correctly identifies 254 and 255', () => {
  assert.equal(detectCountryCode('254712345678'), '254');
  assert.equal(detectCountryCode('255712345678'), '255');
  assert.equal(detectCountryCode('256712345678'), null);
});

test('rejects invalid phone formats', () => {
  assert.equal(normalizePhone('071234567'), null); // too short
  assert.equal(normalizePhone('12345'), null);
  assert.equal(normalizePhone('255812345678'), null);
});

test('accepts only positive integer amounts within the Kibubu savings limit', () => {
  assert.equal(positiveAmount(1000), true);
  assert.equal(positiveAmount('150000'), true);
  assert.equal(positiveAmount(MAX_AMOUNT), true);
  assert.equal(positiveAmount(0), false);
  assert.equal(positiveAmount(MAX_AMOUNT + 1), false);
  assert.equal(positiveAmount(10.5), false);
});

test('the app savings ceiling (TSh 1,000,000) is accepted end to end', () => {
  // Kiasi cha juu kabisa kinachoruhusiwa na fomu ya "Weka Akiba" kwenye app.
  assert.equal(positiveAmount(1000000), true);
  assert.equal(positiveAmount(1000001), false);
});

test('sanitizes account references', () => {
  assert.equal(safeReference('KIBUBU_123'), 'KIBUBU_123');
  assert.equal(safeReference('bad reference'), null);
  assert.equal(safeReference('<script>'), null);
});

test('passes Tanzanian numbers through to Daraja unchanged', () => {
  assert.equal(resolveDarajaPhoneNumber('255712345678'), '255712345678');
  assert.equal(resolveDarajaPhoneNumber('255754123456'), '255754123456');
});

test('resolveDarajaPhoneNumber returns null for an empty value', () => {
  assert.equal(resolveDarajaPhoneNumber(''), null);
  assert.equal(resolveDarajaPhoneNumber(null), null);
});

test('getFirestore gracefully returns null and logs warning if credentials missing', () => {
  const { getFirestore } = require('../src/server');
  const db = getFirestore();
  assert.equal(db, null);
});