require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const fs = require('fs');
const path = require('path');
const axios = require('axios');
const express = require('express');
const cors = require('cors');
let admin = null;
try {
  admin = require('firebase-admin');
} catch {
  // firebase-admin module optional
}
const {
  normalizePhone,
  resolveDarajaPhoneNumber,
  DEFAULT_SANDBOX_PHONE,
  positiveAmount,
  safeReference,
} = require('./validation');

const app = express();
app.use(cors());
app.options('*', cors());
app.use(express.json({ limit: '32kb' }));

app.get('/', (req, res) => {
  res.json({
    status: 'online',
    service: 'Kibubu M-Pesa API',
    message: 'Kibubu Backend API is running',
    endpoints: {
      health: '/health',
      status: '/api/status',
      stkPush: '/api/v1/stkpush',
      callback: '/api/v1/mpesa-callback',
      testDashboard: '/dashboard',
    },
  });
});

app.get(['/dashboard', '/test'], (_req, res) => {
  res.sendFile(path.join(__dirname, '../public/index.html'));
});

app.use(express.static(path.join(__dirname, '../public'), { index: false }));

const mpesaBaseUrl = process.env.MPESA_ENV === 'production'
  ? 'https://api.safaricom.co.ke'
  : 'https://sandbox.safaricom.co.ke';

let firestore = null;
let firebaseInitialized = false;

function getFirestore() {
  if (firebaseInitialized) return firestore;
  firebaseInitialized = true;

  if (!admin) {
    console.warn('[Firebase] Skipping DB write - firebase-admin not installed');
    return null;
  }

  // Determine credential path: check GOOGLE_APPLICATION_CREDENTIALS or standard firebase-admin.json / service-account.json
  const envCredPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const candidates = [
    envCredPath,
    envCredPath ? path.resolve(__dirname, '..', envCredPath) : null,
    path.resolve(__dirname, '../firebase-admin.json'),
    path.resolve(__dirname, '../service-account.json'),
  ].filter(Boolean);

  let validCredFile = null;
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      try {
        const raw = fs.readFileSync(candidate, 'utf8');
        const parsed = JSON.parse(raw);
        if (parsed && (parsed.project_id || parsed.type === 'service_account')) {
          validCredFile = candidate;
          break;
        }
      } catch {
        // Invalid json format in candidate file
      }
    }
  }

  if (!validCredFile) {
    console.warn('[Firebase] Skipping DB write - firebase-admin.json not configured');
    return null;
  }

  try {
    if (admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert(validCredFile),
      });
    }
    firestore = admin.firestore();
    return firestore;
  } catch (err) {
    console.warn('[Firebase] Skipping DB write - firebase-admin.json not configured (init error:', err.message, ')');
    return null;
  }
}

function getConfig() {
  const consumerKey = process.env.MPESA_CONSUMER_KEY || process.env.DARAJA_CONSUMER_KEY;
  const consumerSecret = process.env.MPESA_CONSUMER_SECRET || process.env.DARAJA_CONSUMER_SECRET;
  const shortcode = process.env.MPESA_SHORTCODE;
  const passkey = process.env.MPESA_PASSKEY;
  const callbackUrl = process.env.CALLBACK_URL;

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

async function getAccessToken() {
  const { consumerKey, consumerSecret } = getConfig();
  const auth = Buffer.from(`${consumerKey}:${consumerSecret}`).toString('base64');
  try {
    const response = await axios.get(
      `${mpesaBaseUrl}/oauth/v1/generate?grant_type=client_credentials`,
      { headers: { Authorization: `Basic ${auth}` }, timeout: 15000 },
    );
    return response.data.access_token;
  } catch (error) {
    console.error('[M-Pesa OAuth Error] Failed to generate access token:', {
      status: error.response?.status,
      data: error.response?.data,
      message: error.message,
    });
    const darajaError = error.response?.data?.errorMessage || error.response?.data?.error || error.message;
    const err = new Error(`OAuth token generation failed: ${darajaError}`);
    err.status = error.response?.status || 500;
    err.details = error.response?.data;
    throw err;
  }
}

app.get('/api/status', (_req, res) => res.json({
  status: 'running',
  service: 'kibubu-mpesa-server',
  health: '/health',
  timestamp: new Date().toISOString()
}));

app.get('/health', (_req, res) => res.json({ ok: true }));

app.post('/api/v1/stkpush', async (req, res) => {
  try {
    const isSandbox = process.env.MPESA_ENV !== 'production';
    const phoneNumber = normalizePhone(req.body?.phoneNumber, isSandbox);
    const amount = req.body?.amount;
    const accountReference = safeReference(req.body?.accountReference);
    if (!phoneNumber) {
      return res.status(400).json({
        error: isSandbox
          ? 'phoneNumber must be 2557XXXXXXXX or test format 2547XXXXXXXX.'
          : 'phoneNumber must be 2557XXXXXXXX.'
      });
    }
    if (!positiveAmount(amount)) {
      return res.status(400).json({ error: 'amount must be a positive integer up to 150000.' });
    }
    if (!accountReference) {
      return res.status(400).json({ error: 'accountReference contains invalid characters.' });
    }

    // In Daraja Sandbox, Tanzanian numbers (255...) return 400.002.02 Invalid PhoneNumber.
    // Substitute 255 numbers with Daraja Sandbox test number (254708374149) in sandbox mode,
    // while preserving original phoneNumber in logs and production mode.
    const darajaPartyPhone = resolveDarajaPhoneNumber(phoneNumber, isSandbox);

    const { shortcode, passkey, callbackUrl } = getConfig();
    const token = await getAccessToken();
    const timestamp = new Date().toISOString().replace(/[^0-9]/g, '').slice(0, 14);

    if (!timestamp || timestamp.length !== 14) {
      console.error('[STK Push Error] Invalid timestamp generated:', timestamp);
      return res.status(500).json({ error: 'Failed to generate valid M-Pesa timestamp.' });
    }

    const password = Buffer.from(`${shortcode}${passkey}${timestamp}`).toString('base64');
    const payload = {
      BusinessShortCode: shortcode,
      Password: password,
      Timestamp: timestamp,
      TransactionType: 'CustomerPayBillOnline',
      Amount: Number(amount),
      PartyA: darajaPartyPhone,
      PartyB: shortcode,
      PhoneNumber: darajaPartyPhone,
      CallBackURL: callbackUrl,
      AccountReference: accountReference,
      TransactionDesc: 'Malipo ya Kibubu',
    };

    console.log('[STK Push Request] Sending payload to Daraja:', {
      endpoint: `${mpesaBaseUrl}/mpesa/stkpush/v1/processrequest`,
      shortcode,
      phoneNumber,
      darajaPartyPhone,
      isSandbox,
      amount: Number(amount),
      accountReference,
      callbackUrl,
    });

    const response = await axios.post(
      `${mpesaBaseUrl}/mpesa/stkpush/v1/processrequest`,
      payload,
      { headers: { Authorization: `Bearer ${token}` }, timeout: 20000 },
    );
    const result = response.data;
    console.log('[STK Push Success] Daraja response:', result);

    if (result.CheckoutRequestID) {
      const db = getFirestore();
      if (db) {
        try {
          await db.collection('mpesaOrders').doc(result.CheckoutRequestID).set({
            status: 'PENDING',
            phoneNumber,
            amount: Number(amount),
            accountReference,
            merchantRequestId: result.MerchantRequestID ?? null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } catch (dbError) {
          console.warn('[Firebase] Skipping DB write - error writing to Firestore:', dbError.message);
        }
      }
    }
    return res.status(200).json(result);
  } catch (error) {
    const status = error.response?.status || error.status || 500;
    const darajaData = error.response?.data || error.details;

    console.error('[STK Push Error] Details:', {
      status,
      message: error.message,
      darajaResponse: darajaData,
    });

    const darajaErrorMessage =
      darajaData?.errorMessage ||
      darajaData?.ResponseDescription ||
      darajaData?.error ||
      error.message ||
      'Failed to initiate STK Push';

    return res.status(status).json({
      error: darajaErrorMessage,
      details: darajaData || null,
      errorCode: darajaData?.errorCode || null,
      requestId: darajaData?.requestId || null,
    });
  }
});

app.post('/api/v1/mpesa-callback', async (req, res) => {
const callbackData = req.body?.Body?.stkCallback;
try {
  if (!callbackData?.CheckoutRequestID) {
    return res.status(400).json({ ResultCode: 1, ResultDesc: 'Invalid callback' });
  }
  const db = getFirestore();
  if (db) {
    const orderRef = db.collection('mpesaOrders').doc(callbackData.CheckoutRequestID);
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
        paidAt: admin ? admin.firestore.FieldValue.serverTimestamp() : new Date(),
      }, { merge: true });
    } else {
      await orderRef.set({
        status: 'FAILED',
        resultCode: callbackData.ResultCode,
        resultDesc: callbackData.ResultDesc ?? 'Payment failed',
        failedAt: admin ? admin.firestore.FieldValue.serverTimestamp() : new Date(),
      }, { merge: true });
    }
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

module.exports = {
  app,
  getFirestore,
  normalizePhone,
  resolveDarajaPhoneNumber,
  DEFAULT_SANDBOX_PHONE,
  positiveAmount,
  safeReference,
};
