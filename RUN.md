# Kibubu — Jinsi ya Kuchezesha (Run) na Kufanya Majaribio ya M-Pesa

Mwongozo wa haraka wa kuendesha app na kupima kuweka pesa (deposit) kwa M-Pesa
STK Push kupitia backend ya Render: `https://kibubu-backend.onrender.com`.

## 1. Ukurasa unaohusika na malipo

- **`lib/pages/add_money_page.dart`** — `AddMoneyPage` ("WEKA AKIBA 💵”).
  Hapa mtumiaji huchagua mtandao, namba ya simu, kiasi na kubonyeza
  `LIPA NA M-PESA 📲`.
- **`lib/services/payment_service.dart`** — `PaymentService.processPayment()`
  hutuma ombi la STK Push (`POST /api/v1/stkpush`) kwenda backend.
  Base URL ya default ni `https://kibubu-backend.onrender.com`.

Ukurasa unaingizwa kutoka:
- `lib/pages/goal_pages.dart` (kitufe cha "Weka Akiba")
- `lib/pages/dashboard_page.dart`

## 2. Namba ya simu
- Namba za **Tanzania pekee** zinakubaliwa: `0754...`, `0742...`, `076...` n.k.
- Server huzibadilisha kuwa format ya `255XXXXXXXXX` na kuzituma kwa Daraja
  **kama zilivyo** — hakuna kubadilisha kwenda namba ya Kenya.
- Namba ya Kenya (`254...`) haikubaliwi.

## 3. Kuchezesha app
```powershell
# Weka System32 (PowerShell), Flutter na Git kwenye PATH ya session hii
$env:Path = "$env:SystemRoot\System32;$env:SystemRoot\System32\WindowsPowerShell\v1.0;C:\src\flutter\bin;C:\Program Files\Git\cmd;$env:Path"

cd C:\Users\HomePC\documents\ChatGPT\kibubu

# Chaguo A: kwenye Chrome (rahisi kwa majaribio)
flutter run -d chrome --dart-define=MPESA_API_BASE_URL=https://kibubu-backend.onrender.com

# Chaguo B: kwenye emulator/simu ya Android
flutter run --dart-define=MPESA_API_BASE_URL=https://kibubu-backend.onrender.com

# Chaguo C: bila backend (fallback ya ndani, hali = PENDING)
flutter run -d chrome --dart-define=MPESA_API_BASE_URL=
```

> Kumbuka: backend ya Render tayari ni default, hivyo
> `--dart-define=MPESA_API_BASE_URL=...` si lazima. Wasilisha define kama
> unataka kutumia URL nyingine.

## 4. Kuchezesha backend (kwa majaribio ya ndani)

```powershell
$env:Path = "C:\Program Files\nodejs;$env:Path"
cd C:\Users\HomePC\documents\ChatGPT\kibubu\server
npm install
npm test        # tests 18/18 (npm test hutumia `node --test test/*.test.js`)
npm start       # starta kwenye PORT kutoka .env (5000)
```

Endpoints:
- `GET  /health`
- `GET  /api/status`
- `POST /api/v1/stkpush`
- `GET  /api/v1/order-status?checkoutRequestId=...` (hali ya oda baada ya callback)
- `POST /api/v1/mpesa-callback`
- `GET  /dashboard` (M-Pesa Test Center ya HTML)

## 5. Mtiriko wa majaribio ya kuweka pesa

1. Fungua `AddMoneyPage` → chagua mtandao → weka namba → weka kiasi (≥ 1000,
   kiwango cha juu TSh 1,000,000).
2. Bonyeza `LIPA NA M-PESA 📲` → thibitisha kwenye dialog.
3. App inatuma `POST https://kibubu-backend.onrender.com/api/v1/stkpush`
   na `{ phoneNumber, amount, accountReference }`.
4. Server inarejesha `CheckoutRequestID`; app inaonyesha hali `PENDING`
   hadi callback ya Safaricom ithibitishe malipo.
5. Thibitisha PIN kwenye simu. Baada ya callback, angalia hali kwa
   `GET /api/v1/order-status?checkoutRequestId=<CheckoutRequestID>` au kitufe
   cha **3. Angalia Hali ya Oda** kwenye `/dashboard` — status inakuwa `PAID`.

## 6. Kuweka credentials mpya za Daraja Sandbox
Credentials zilizopo kwenye `server/.env` zimepitwa na muda (server inajibu
`400 OAuth error`). Kupata mpya:

1. Nenda [developer.safaricom.co.ke](https://developer.safaricom.co.ke) na
   ingia (au jiunge bure).
2. Unda app → chagua **Lipa Na M-Pesa Sandbox**. Utapata **Consumer Key** na
   **Consumer Secret**.
3. Weka kwenye `.env` kwa amri moja (utchukue key/secret kutoka Daraja):

```powershell
cd server
node scripts/set-credentials.js <CONSUMER_KEY> <CONSUMER_SECRET>
```

Shortcode ya sandbox (`174379`) na passkey ni za kawaida (zimo kwenye `.env`).

4. Pima moja kwa moja kwa namba ya Tanzania:

```powershell
# Terminal 1
npm start
# Terminal 2
node scripts/test-stk.js 0754123456 1000
```

Ukitaka matokeo ya callback, hakikisha `CALLBACK_URL` inaelekea URL ya backend
yako ya Render inayofikika hadharani (Daraja hukataa `http://` na `localhost`),
na Firebase Admin service account imewekwa ili oda ihifadhiwe kwenye
`mpesaOrders/{CheckoutRequestID}` na callback iweze kuisasisha.

## 7. Vigezo vya mazingira (server/.env)

```dotenv
DARAJA_CONSUMER_KEY=...
DARAJA_CONSUMER_SECRET=...
MPESA_SHORTCODE=174379
MPESA_PASSKEY=bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919
CALLBACK_URL=https://kibubu-backend.onrender.com/api/v1/mpesa-callback
PORT=5000
MPESA_ENV=sandbox
```
