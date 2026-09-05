require('dotenv').config();

const axios = require('axios');
const express = require('express');
const admin = require('firebase-admin');
const { normalizePhone, positiveAmount, safeReference } = require('./validation');

const app = express();
app.use(express.json({ limit: '32kb' }));

const mpesaBaseUrl = process.env.MPESA_ENV === 'production'
  ? 'https://api.safaricom.co.ke'
  : 'https://sandbox.safaricom.co.ke';

let firestore;
function getFirestore() {
  if (firestore) return firestore;
  if (admin.apps.length === 0) {
    admin.initializeApp();
  }
  firestore = admin.firestore();
  return firestore;
}

function assertConfig() {
  const required = [
    'DARAJA_CONSUMER_KEY',
    'DARAJA_CONSUMER_SECRET',
    'MPESA_SHORTCODE',
    'MPESA_PASSKEY',
    'CALLBACK_URL',
  ];
  const missing = required.filter((name) => !process.env[name]);
  if (missing.length > 0) {
    throw new Error(`Missing M-Pesa configuration: ${missing.join(', ')}`);
  }
  if (!process.env.CALLBACK_URL.startsWith('https://')) {
    throw new Error('CALLBACK_URL must be a live HTTPS endpoint.');
  }
}

async function getAccessToken() {
  assertConfig();
  const auth = Buffer.from(
    `${process.env.DARAJA_CONSUMER_KEY}:${process.env.DARAJA_CONSUMER_SECRET}`,
  ).toString('base64');
  const response = await axios.get(
    `${mpesaBaseUrl}/oauth/v1/generate?grant_type=client_credentials`,
    { headers: { Authorization: `Basic ${auth}` }, timeout: 15000 },
  );
  return response.data.access_token;
}

app.get('/health', (_req, res) => res.json({ ok: true }));

app.post('/api/v1/stkpush', async (req, res) => {
  try {
    const phoneNumber = normalizePhone(req.body?.phoneNumber);
    const amount = req.body?.amount;
    const accountReference = safeReference(req.body?.accountReference);
    if (!phoneNumber) {
      return res.status(400).json({ error: 'phoneNumber must be 2557XXXXXXXX.' });
    }
    if (!positiveAmount(amount)) {
      return res.status(400).json({ error: 'amount must be a positive integer up to 150000.' });
    }
    if (!accountReference) {
      return res.status(400).json({ error: 'accountReference contains invalid characters.' });
    }

    const token = await getAccessToken();
    const timestamp = new Date().toISOString().replace(/[^0-9]/g, '').slice(0, 14);
    const shortcode = process.env.MPESA_SHORTCODE;
    const password = Buffer.from(
      `${shortcode}${process.env.MPESA_PASSKEY}${timestamp}`,
    ).toString('base64');
    const payload = {
      BusinessShortCode: shortcode,
      Password: password,
      Timestamp: timestamp,
      TransactionType: 'CustomerPayBillOnline',
      Amount: Number(amount),
      PartyA: phoneNumber,
      PartyB: shortcode,
      PhoneNumber: phoneNumber,
      CallBackURL: process.env.CALLBACK_URL,
      AccountReference: accountReference,
      TransactionDesc: 'Malipo ya Kibubu',
    };
    const response = await axios.post(
      `${mpesaBaseUrl}/mpesa/stkpush/v1/processrequest`,
      payload,
      { headers: { Authorization: `Bearer ${token}` }, timeout: 20000 },
    );
    const result = response.data;
    if (result.CheckoutRequestID) {
      await getFirestore().collection('mpesaOrders').doc(result.CheckoutRequestID).set({
        status: 'PENDING',
        phoneNumber,
        amount: Number(amount),
        accountReference,
        merchantRequestId: result.MerchantRequestID ?? null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    return res.status(200).json(result);
  } catch (error) {
    console.error('STK Push Error:', error.response?.data || error.message);
    return res.status(500).json({ error: 'Failed to initiate STK Push' });
  }
});

app.post('/api/v1/mpesa-callback', async (req, res) => {
  const callbackData = req.body?.Body?.stkCallback;
  try {
    if (!callbackData?.CheckoutRequestID) {
      return res.status(400).json({ ResultCode: 1, ResultDesc: 'Invalid callback' });
    }
    const orderRef = getFirestore().collection('mpesaOrders').doc(callbackData.CheckoutRequestID);
    const orderSnapshot = await orderRef.get();
    if (!orderSnapshot.exists) {
      console.warn(`Ignoring callback for unknown checkout: ${callbackData.CheckoutRequestID}`);
      return res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });
    }
    if (callbackData.ResultCode === 0) {
      const items = callbackData.CallbackMetadata?.Item ?? [];
      const metadata = Object.fromEntries(items.map((item) => [item.Name, item.Value]));
      await orderRef.set({
        status: 'PAID',
        amount: metadata.Amount ?? null,
        mpesaReceiptNumber: metadata.MpesaReceiptNumber ?? null,
        phoneNumber: metadata.PhoneNumber ?? null,
        resultCode: callbackData.ResultCode,
        resultDesc: callbackData.ResultDesc ?? null,
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    } else {
      await orderRef.set({
        status: 'FAILED',
        resultCode: callbackData.ResultCode,
        resultDesc: callbackData.ResultDesc ?? 'Payment failed',
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    return res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });
  } catch (error) {
    console.error('M-Pesa callback error:', error.message);
    return res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });
  }
});

if (require.main === module) {
  const port = Number(process.env.PORT || 3000);
  app.listen(port, () => console.log(`Server running on port ${port}`));
}

module.exports = { app, normalizePhone, positiveAmount, safeReference };
