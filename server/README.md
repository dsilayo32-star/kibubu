# Kibubu M-Pesa backend

This Express service owns Safaricom Daraja credentials and starts STK Push requests. Do not put Daraja secrets in Flutter or commit `.env`/`service-account.json`.

## Setup

```bash
cd server
npm install
copy .env.example .env
npm test
npm start
```

Set the following in `.env`:

- `DARAJA_CONSUMER_KEY`
- `DARAJA_CONSUMER_SECRET`
- `MPESA_SHORTCODE`
- `MPESA_PASSKEY`
- `CALLBACK_URL`: a public HTTPS URL ending in `/api/v1/mpesa-callback`
- `PORT`
- `MPESA_ENV=sandbox` while testing, then `production` for live Daraja
- `GOOGLE_APPLICATION_CREDENTIALS`: path to a Firebase Admin service-account JSON

The Firebase Admin SDK uses the existing Firebase project `kibubu-981a0`. The STK endpoint writes a pending document to `mpesaOrders/{CheckoutRequestID}`. The callback only updates an existing pending document, marks successful payments `PAID`, and stores `mpesaReceiptNumber`, amount, phone and Safaricom result data.

## Flutter connection

Run the Flutter app with the public backend URL:

```bash
flutter run -d chrome --dart-define=MPESA_API_BASE_URL=https://your-domain.example
```

When the define is omitted, Flutter keeps the local pending-payment fallback for development and tests.

## Endpoints

- `GET /health`
- `POST /api/v1/stkpush`
- `POST /api/v1/mpesa-callback` (Safaricom webhook)

Phone numbers are normalized to `2557XXXXXXXX`; references allow only letters, numbers, `_` and `-`. Amounts must be positive integers up to `150000`.
