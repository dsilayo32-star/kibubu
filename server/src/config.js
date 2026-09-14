'use strict';

// Centralized M-Pesa / Daraja configuration.
// All environment access is funneled through here so the rest of the app never
// touches process.env directly (Dependency Inversion + Single Responsibility).

const SANDBOX_BASE_URL = 'https://sandbox.safaricom.co.ke';
const PRODUCTION_BASE_URL = 'https://api.safaricom.co.ke';

// Vodacom Tanzania OpenAPI URLs
const VODACOM_SANDBOX_BASE_URL = 'https://openapi.m-pesa.com:443/sandbox/ipg/v2/vodacomTZN';
const VODACOM_PRODUCTION_BASE_URL = 'https://openapi.m-pesa.com:443/openapi/ipg/v2/vodacomTZN';

// Safaricom posts the payment result here. Override with CALLBACK_URL in the
// environment; this is only the last-resort default when it is unset.
const DEFAULT_CALLBACK_URL = 'https://kibubu-backend.onrender.com/api/v1/mpesa-callback';

/**
 * Builds the CallBackURL sent to Daraja.
 *
 * Daraja rejects anything that is not a publicly resolvable HTTPS URL, and a
 * stray space or quote carried in from a .env line makes the callback silently
 * undeliverable, so the value is trimmed and stripped of surrounding quotes
 * before it is used.
 *
 * @param {object} env
 * @returns {string} an https:// URL with no trailing whitespace
 */
function resolveCallbackUrl(env = process.env) {
  const raw = env.CALLBACK_URL;

  // Treat a blank/whitespace-only value the same as an unset one.
  const candidate = typeof raw === 'string' ? raw.trim().replace(/^['"]|['"]$/g, '').trim() : '';

  return candidate || DEFAULT_CALLBACK_URL;
}

const isProduction = () => process.env.MPESA_ENV === 'production';
const isSandbox = () => !isProduction();

function getMpesaBaseUrl() {
  return isProduction() ? PRODUCTION_BASE_URL : SANDBOX_BASE_URL;
}

const isVodacomProduction = () => (process.env.VODACOM_ENV || process.env.MPESA_ENV) === 'production';
const isVodacomSandbox = () => !isVodacomProduction();

function getVodacomBaseUrl() {
  return isVodacomProduction() ? VODACOM_PRODUCTION_BASE_URL : VODACOM_SANDBOX_BASE_URL;
}

/**
 * Reads Vodacom Tanzania credentials from environment.
 * If credentials are not present, can run in mock simulation mode for testing.
 */
function getVodacomConfig(env = process.env) {
  const apiKey = env.VODACOM_API_KEY || env.VODACOM_MPESA_API_KEY;
  const publicKey = env.VODACOM_PUBLIC_KEY || env.VODACOM_MPESA_PUBLIC_KEY;
  const serviceProviderCode = env.VODACOM_SERVICE_PROVIDER_CODE || env.VODACOM_SHORTCODE || '000000';
  const baseUrl = getVodacomBaseUrl();

  const isConfigured = Boolean(apiKey && publicKey);
  const isMock = !isConfigured || env.VODACOM_MOCK === 'true';

  return {
    apiKey,
    publicKey,
    serviceProviderCode,
    baseUrl,
    isConfigured,
    isMock,
  };
}

/**
 * Reads and validates the Daraja credentials required to talk to Safaricom.
 * Throws with a descriptive message when configuration is incomplete or the
 * callback URL is not a live HTTPS endpoint.
 */
function getConfig(env = process.env) {
  const consumerKey = env.MPESA_CONSUMER_KEY || env.DARAJA_CONSUMER_KEY;
  const consumerSecret = env.MPESA_CONSUMER_SECRET || env.DARAJA_CONSUMER_SECRET;
  const shortcode = env.MPESA_SHORTCODE;
  const passkey = env.MPESA_PASSKEY;
  const callbackUrl = resolveCallbackUrl(env);

  const missing = [];
  if (!consumerKey) missing.push('MPESA_CONSUMER_KEY (or DARAJA_CONSUMER_KEY)');
  if (!consumerSecret) missing.push('MPESA_CONSUMER_SECRET (or DARAJA_CONSUMER_SECRET)');
  if (!shortcode) missing.push('MPESA_SHORTCODE');
  if (!passkey) missing.push('MPESA_PASSKEY');

  if (missing.length > 0) {
    const errorMsg = `Missing M-Pesa environment configuration: ${missing.join(', ')}`;
    console.error(`[M-Pesa Config Error] ${errorMsg}`);
    throw new Error(errorMsg);
  }

  // CallbackURL always arrives from resolveCallbackUrl(), so a missing
  // CALLBACK_URL falls back to the default rather than failing the request.
  // Only an explicitly-provided non-HTTPS value is a hard error.
  if (!callbackUrl.startsWith('https://')) {
    const errorMsg = 'CALLBACK_URL must be a live HTTPS endpoint (http://, localhost and blank are rejected).';
    console.error(`[M-Pesa Config Error] ${errorMsg} Got: ${callbackUrl}`);
    throw new Error(errorMsg);
  }

  return { consumerKey, consumerSecret, shortcode, passkey, callbackUrl };
}

module.exports = {
  SANDBOX_BASE_URL,
  PRODUCTION_BASE_URL,
  VODACOM_SANDBOX_BASE_URL,
  VODACOM_PRODUCTION_BASE_URL,
  DEFAULT_CALLBACK_URL,
  isProduction,
  isSandbox,
  isVodacomProduction,
  isVodacomSandbox,
  getMpesaBaseUrl,
  getVodacomBaseUrl,
  getVodacomConfig,
  resolveCallbackUrl,
  getConfig,
};
