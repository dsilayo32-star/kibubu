const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizePhone,
  positiveAmount,
  safeReference,
} = require('../src/validation');

test('normalizes accepted Tanzanian mobile formats to 2557XXXXXXXX', () => {
  assert.equal(normalizePhone('0712 345 678'), '255712345678');
  assert.equal(normalizePhone('+255712345678'), '255712345678');
  assert.equal(normalizePhone('255712345678'), '255712345678');
});

test('rejects invalid phone formats', () => {
  assert.equal(normalizePhone('071234567'), null);
  assert.equal(normalizePhone('254712345678'), null);
  assert.equal(normalizePhone('255812345678'), null);
});

test('accepts only positive integer amounts within Daraja limit', () => {
  assert.equal(positiveAmount(1000), true);
  assert.equal(positiveAmount('150000'), true);
  assert.equal(positiveAmount(0), false);
  assert.equal(positiveAmount(150001), false);
  assert.equal(positiveAmount(10.5), false);
});

test('sanitizes account references', () => {
  assert.equal(safeReference('KIBUBU_123'), 'KIBUBU_123');
  assert.equal(safeReference('bad reference'), null);
  assert.equal(safeReference('<script>'), null);
});