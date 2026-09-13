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

Credentials za Daraja zinawekwa kwa script (usanifu usiofichua siri kwenye
historia ya shell):

```bash
node scripts/set-credentials.js <CONSUMER_KEY> <CONSUMER_SECRET>
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

Run the Flutter app with the public backend URL (this is the deployed Render
service; when the define is omitted the app already defaults to it):

```bash
flutter run --dart-define=MPESA_API_BASE_URL=https://kibubu-backend.onrender.com
```

For a pure local run with no backend, point the define at an empty string to use
the built-in pending-payment fallback:

```bash
flutter run --dart-define=MPESA_API_BASE_URL=
```

## Endpoints
- `GET /health`
- `POST /api/v1/stkpush`
- `GET /api/v1/order-status?checkoutRequestId=...` — returns `PENDING` / `PAID` / `FAILED` for an order created by `stkpush`
- `POST /api/v1/mpesa-callback` (Safaricom webhook)
- `GET /dashboard` — browser test centre for STK Push + order status
Only Tanzanian phone numbers are accepted and normalized to `2557XXXXXXXX`; they are forwarded to Daraja unchanged. References allow only letters, numbers, `_` and `-`. Amounts must be positive integers up to `MAX_AMOUNT` (`1000000`, the deposit ceiling in the Flutter app).

The callback only updates an order that `stkpush` already created, so a payment is confirmed by polling `/api/v1/order-status` after Safaricom posts the result — the app itself stays `PENDING` until that happens.
