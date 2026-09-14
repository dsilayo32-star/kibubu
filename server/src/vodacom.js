'use strict';

const axios = require('axios');
const crypto = require('crypto');
const { getVodacomConfig, isVodacomSandbox } = require('./config');

/**
 * Encrypts an API key or Session ID with the Vodacom OpenAPI public key (RSA PKCS#1 v1.5).
 * @param {string} textToEncrypt 
 * @param {string} publicKeyBase64 
 * @returns {string} base64 encoded encrypted string
 */
function encryptVodacomKey(textToEncrypt, publicKeyBase64) {
  let cleanKey = (publicKeyBase64 || '').trim();
  cleanKey = cleanKey.replace(/-----BEGIN PUBLIC KEY-----/g, '')
                     .replace(/-----END PUBLIC KEY-----/g, '')
                     .replace(/[\r\n\s]/g, '');

  const formattedPem = `-----BEGIN PUBLIC KEY-----\n${cleanKey}\n-----END PUBLIC KEY-----`;

  return crypto.publicEncrypt(
    {
      key: formattedPem,
      padding: crypto.constants.RSA_PKCS1_PADDING,
    },
    Buffer.from(textToEncrypt, 'utf8')
  ).toString('base64');
}

/**
 * Requests a Session ID from Vodacom OpenAPI.
 * @returns {Promise<string>}
 */
async function getVodacomSessionId() {
  const { apiKey, publicKey, baseUrl } = getVodacomConfig();

  const encryptedApiKey = encryptVodacomKey(apiKey, publicKey);
  const endpoint = `${baseUrl}/getSession/`;

  const response = await axios.get(endpoint, {
    headers: {
      Accept: 'application/json',
      Origin: '*',
      Authorization: `Bearer ${encryptedApiKey}`,
    },
    timeout: 15000,
  });

  const data = response.data;
  if (!data?.output_SessionID) {
    const errorMsg = data?.output_ResponseDesc || data?.errorMessage || 'Failed to retrieve Vodacom session ID';
    const err = new Error(errorMsg);
    err.details = data;
    throw err;
  }

  return data.output_SessionID;
}

/**
 * Initiates a C2B Payment (USSD / STK Push equivalent for Vodacom Tanzania).
 *
 * @param {object} params
 * @param {string} params.phoneNumber - e.g. 255712345678
 * @param {number|string} params.amount
 * @param {string} params.accountReference
 * @returns {Promise<object>}
 */
async function initiateVodacomPayment({ phoneNumber, amount, accountReference }) {
  const { apiKey, publicKey, serviceProviderCode, baseUrl, isMock } = getVodacomConfig();

  // If in mock mode (credentials not configured or testing), return a mock accepted response
  if (isMock) {
    const conversationId = `VOD_MOCK_${Date.now()}`;
    const transactionId = `TZN_${Math.random().toString(36).substring(2, 10).toUpperCase()}`;
    return {
      output_ResponseCode: 'INS-0',
      output_ResponseDesc: 'Request processed successfully (Vodacom Sandbox Mock)',
      output_TransactionID: transactionId,
      output_ConversationID: conversationId,
      output_ThirdPartyConversationID: accountReference,
      // Compatibility fields for the dashboard and app
      CheckoutRequestID: conversationId,
      MerchantRequestID: transactionId,
      ResponseCode: '0',
      ResponseDescription: 'Success. Request accepted for processing (Vodacom M-Pesa)',
      CustomerMessage: 'Success. Request accepted for processing (Vodacom M-Pesa)',
      provider: 'vodacom',
    };
  }

  const sessionId = await getVodacomSessionId();
  const encryptedSession = encryptVodacomKey(sessionId, publicKey);

  const endpoint = `${baseUrl}/c2bPayment/singleStage/`;
  const conversationId = `KIBUBU_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

  const payload = {
    input_Amount: Number(amount),
    input_Country: 'TZN',
    input_Currency: 'TZS',
    input_CustomerMSISDN: phoneNumber,
    input_ServiceProviderCode: serviceProviderCode,
    input_ThirdPartyConversationID: conversationId,
    input_TransactionReference: accountReference.slice(0, 20),
    input_PurchasedItemsDesc: 'Kibubu Savings Deposit',
  };

  const response = await axios.post(endpoint, payload, {
    headers: {
      Accept: 'application/json',
      Origin: '*',
      Authorization: `Bearer ${encryptedSession}`,
    },
    timeout: 20000,
  });

  const resData = response.data;
  return {
    ...resData,
    // Normalise to common interface
    CheckoutRequestID: resData.output_ConversationID || resData.output_TransactionID || conversationId,
    MerchantRequestID: resData.output_TransactionID || conversationId,
    ResponseCode: resData.output_ResponseCode === 'INS-0' ? '0' : resData.output_ResponseCode,
    ResponseDescription: resData.output_ResponseDesc || 'Request accepted',
    CustomerMessage: resData.output_ResponseDesc || 'Request accepted',
    provider: 'vodacom',
  };
}

/**
 * Normalizes an error from Vodacom OpenAPI into { status, data, message }.
 */
function extractVodacomError(error) {
  const status = error.response?.status || error.status || 500;
  const data = error.response?.data || error.details;
  const message =
    data?.output_ResponseDesc ||
    data?.errorMessage ||
    data?.error ||
    error.message ||
    'Failed to initiate Vodacom M-Pesa payment';

  return { status, data, message };
}

module.exports = {
  encryptVodacomKey,
  getVodacomSessionId,
  initiateVodacomPayment,
  extractVodacomError,
};
