'use strict';

const axios = require('axios');
const { getConfig, getMpesaBaseUrl, isSandbox } = require('./config');

const TRANSACTION_TYPE = 'CustomerPayBillOnline';
const TRANSACTION_DESC = 'Malipo ya Kibubu';

/**
 * Generates the Daraja timestamp: YYYYMMDDHHmmss (14 digits).
 */
function generateTimestamp(date = new Date()) {
  return date.toISOString().replace(/[^0-9]/g, '').slice(0, 14);
}

/**
 * Builds the STK Push password: base64(shortcode + passkey + timestamp).
 */
function generatePassword(shortcode, passkey, timestamp) {
  return Buffer.from(`${shortcode}${passkey}${timestamp}`).toString('base64');
}

/**
 * Fetches a Daraja OAuth access token using the configured consumer credentials.
 * On failure, throws an error carrying `.status` and `.details` so the route
 * layer can translate it into a proper HTTP response.
 */
async function getAccessToken() {
  const { consumerKey, consumerSecret } = getConfig();
  const auth = Buffer.from(`${consumerKey}:${consumerSecret}`).toString('base64');

  try {
    const response = await axios.get(
      `${getMpesaBaseUrl()}/oauth/v1/generate?grant_type=client_credentials`,
      { headers: { Authorization: `Basic ${auth}` }, timeout: 15000 },
    );
    return response.data.access_token;
  } catch (error) {
    console.error('[M-Pesa OAuth Error] Failed to generate access token:', {
      status: error.response?.status,
      data: error.response?.data,
      message: error.message,
    });

    const darajaError =
      error.response?.data?.errorMessage || error.response?.data?.error || error.message;
    const err = new Error(`OAuth token generation failed: ${darajaError}`);
    err.status = error.response?.status || 500;
    err.details = error.response?.data;
    throw err;
  }
}

/**
 * Sends an STK Push request to Daraja and returns the parsed response body.
 * @param {object} params
 * @param {string} params.darajaPartyPhone - phone to charge (already resolved for sandbox)
 * @param {number|string} params.amount
 * @param {string} params.accountReference
 */
async function initiateStkPush({ darajaPartyPhone, amount, accountReference, phoneNumber }) {
  const { shortcode, passkey, callbackUrl } = getConfig();
  const token = await getAccessToken();
  const timestamp = generateTimestamp();

  if (!timestamp || timestamp.length !== 14) {
    console.error('[STK Push Error] Invalid timestamp generated:', timestamp);
    const err = new Error('Failed to generate valid M-Pesa timestamp.');
    err.status = 500;
    err.invalidTimestamp = true;
    throw err;
  }

  const payload = {
    BusinessShortCode: shortcode,
    Password: generatePassword(shortcode, passkey, timestamp),
    Timestamp: timestamp,
    TransactionType: TRANSACTION_TYPE,
    Amount: Number(amount),
    PartyA: darajaPartyPhone,
    PartyB: shortcode,
    PhoneNumber: darajaPartyPhone,
    CallBackURL: callbackUrl,
    AccountReference: accountReference,
    TransactionDesc: TRANSACTION_DESC,
  };

  const endpoint = `${getMpesaBaseUrl()}/mpesa/stkpush/v1/processrequest`;
  console.log('[STK Push Request] Sending payload to Daraja:', {
    endpoint,
    shortcode,
    phoneNumber: phoneNumber ?? darajaPartyPhone,
    darajaPartyPhone,
    isSandbox: isSandbox(),
    amount: Number(amount),
    accountReference,
    callbackUrl,
  });

  const response = await axios.post(endpoint, payload, {
    headers: { Authorization: `Bearer ${token}` },
    timeout: 20000,
  });
  console.log('[STK Push Success] Daraja response:', response.data);
  return response.data;
}

/**
 * Normalizes an axios/Daraja error into { status, darajaData, message }.
 */
function extractDarajaError(error) {
  const status = error.response?.status || error.status || 500;
  const darajaData = error.response?.data || error.details;
  const message =
    darajaData?.errorMessage ||
    darajaData?.ResponseDescription ||
    darajaData?.error ||
    error.message ||
    'Failed to initiate STK Push';

  return { status, darajaData, message };
}

module.exports = {
  TRANSACTION_TYPE,
  TRANSACTION_DESC,
  generateTimestamp,
  generatePassword,
  getAccessToken,
  initiateStkPush,
  extractDarajaError,
};
