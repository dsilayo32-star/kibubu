'use strict';

// Centralized M-Pesa / Daraja configuration.
// All environment access is funneled through here so the rest of the app never
// touches process.env directly (Dependency Inversion + Single Responsibility).

const SANDBOX_BASE_URL = 'https://sandbox.safaricom.co.ke';
const PRODUCTION_BASE_URL = 'https://api.safaricom.co.ke';

const isProduction = () => process.env.MPESA_ENV === 'production';
const isSandbox = () => !isProduction();

function getMpesaBaseUrl() {
  return isProduction() ? PRODUCTION_BASE_URL : SANDBOX_BASE_URL;
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
  const callbackUrl = env.CALLBACK_URL;

  const missing = [];
  if (!consumerKey) missing.push('MPESA_CONSUMER_KEY (or DARAJA_CONSUMER_KEY)');
  if (!consumerSecret) missing.push('MPESA_CONSUMER_SECRET (or DARAJA_CONSUMER_SECRET)');
  if (!shortcode) missing.push('MPESA_SHORTCODE');
  if (!passkey) missing.push('MPESA_PASSKEY');
  if (!callbackUrl) missing.push('CALLBACK_URL');

  if (missing.length > 0) {
    const errorMsg = `Missing M-Pesa environment configuration: ${missing.join(', ')}`;
    console.error(`[M-Pesa Config Error] ${errorMsg}`);
    throw new Error(errorMsg);
  }

  if (!callbackUrl.startsWith('https://')) {
    const errorMsg = 'CALLBACK_URL must be a live HTTPS endpoint.';
    console.error(`[M-Pesa Config Error] ${errorMsg} Got: ${callbackUrl}`);
    throw new Error(errorMsg);
  }

  return { consumerKey, consumerSecret, shortcode, passkey, callbackUrl };
}

module.exports = {
  SANDBOX_BASE_URL,
  PRODUCTION_BASE_URL,
  isProduction,
  isSandbox,
  getMpesaBaseUrl,
  getConfig,
};
