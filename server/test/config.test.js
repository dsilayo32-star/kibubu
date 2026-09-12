const test = require('node:test');
const assert = require('node:assert/strict');
const { resolveCallbackUrl, DEFAULT_CALLBACK_URL, getConfig } = require('../src/config');

// A minimal env that satisfies every requirement except CALLBACK_URL.
const baseEnv = {
  MPESA_CONSUMER_KEY: 'key',
  MPESA_CONSUMER_SECRET: 'secret',
  MPESA_SHORTCODE: '174379',
  MPESA_PASSKEY: 'passkey',
};

test('falls back to the default when CALLBACK_URL is unset or blank', () => {
  assert.equal(resolveCallbackUrl({}), DEFAULT_CALLBACK_URL);
  assert.equal(resolveCallbackUrl({ CALLBACK_URL: '' }), DEFAULT_CALLBACK_URL);
  assert.equal(resolveCallbackUrl({ CALLBACK_URL: '   ' }), DEFAULT_CALLBACK_URL);
  assert.equal(resolveCallbackUrl({ CALLBACK_URL: '\t\n ' }), DEFAULT_CALLBACK_URL);
});

test('prefers CALLBACK_URL from the environment when present', () => {
  const url = 'https://live.example.com/api/v1/mpesa-callback';
  assert.equal(resolveCallbackUrl({ CALLBACK_URL: url }), url);
});

test('strips surrounding whitespace and quotes from CALLBACK_URL', () => {
  assert.equal(resolveCallbackUrl({ CALLBACK_URL: '  https://x.example/cb  ' }), 'https://x.example/cb');
  assert.equal(resolveCallbackUrl({ CALLBACK_URL: 'https://x.example/cb\n' }), 'https://x.example/cb');
  assert.equal(resolveCallbackUrl({ CALLBACK_URL: '"https://x.example/cb"' }), 'https://x.example/cb');
  assert.equal(resolveCallbackUrl({ CALLBACK_URL: "'https://x.example/cb'" }), 'https://x.example/cb');
});

test('default callback URL is a clean public HTTPS endpoint', () => {
  assert.ok(DEFAULT_CALLBACK_URL.startsWith('https://'), 'must use https://');
  assert.ok(!DEFAULT_CALLBACK_URL.includes('http://'), 'must not use http://');
  assert.ok(!/localhost|127\.0\.0\.1/.test(DEFAULT_CALLBACK_URL), 'must not be localhost');
  assert.ok(!/\s/.test(DEFAULT_CALLBACK_URL), 'must not contain whitespace');
  assert.ok(!DEFAULT_CALLBACK_URL.endsWith('/'), 'must not have a trailing slash');
  // Must match the route actually registered in routes.js.
  assert.ok(DEFAULT_CALLBACK_URL.endsWith('/api/v1/mpesa-callback'), 'must target the real callback route');
});

test('getConfig supplies the fallback rather than throwing on a missing CALLBACK_URL', () => {
  const config = getConfig(baseEnv);
  assert.equal(config.callbackUrl, DEFAULT_CALLBACK_URL);
});

test('getConfig rejects an explicitly-provided non-HTTPS CALLBACK_URL', () => {
  for (const bad of ['http://insecure.example/cb', 'localhost:3000/cb', 'ftp://x/cb']) {
    assert.throws(() => getConfig({ ...baseEnv, CALLBACK_URL: bad }), /live HTTPS endpoint/);
  }
});
