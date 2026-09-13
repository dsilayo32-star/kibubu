# Kibubu

Kibubu ni Flutter app ya kuweka akiba, malengo, historia, mikopo na backup ya Firebase.

## Kuendesha

```bash
flutter pub get
flutter run -d chrome
```

## Firebase

Project ID ni `kibubu-981a0`. Soma [FIREBASE_SETUP.md](FIREBASE_SETUP.md) kwa
FlutterFire configuration, Anonymous Authentication, Firestore na rules.

## M-Pesa Daraja

Backend iko kwenye `server/`. Soma [server/README.md](server/README.md) kwa
`.env`, Firebase Admin service account, STK Push, callback na kuunganisha Flutter
kwa URL ya backend. Secrets za Daraja hazipaswi kuwekwa kwenye Flutter app.

## Tests
```bash
flutter test      # 76/76
flutter analyze   # No issues found
```

Backend:

```bash
cd server && npm test   # 18/18
```

## Malipo (M-Pesa) — hatua ya mwisho
App iko tayari kwa majaribio ya malipo: fomu ya simu inakaguliwa, kiwango cha
kuweka akiba ni TSh 1,000–1,000,000, na hali ya malipo huthibitishwa kwa callback.
Kinachobaki ni credentials halali za Daraja Sandbox (zilizopo kwenye `server/.env`
zimepitwa na muda) — angalia [RUN.md](RUN.md) hatua 6:

```powershell
cd server
node scripts/set-credentials.js <CONSUMER_KEY> <CONSUMER_SECRET>
npm start
node scripts/test-stk.js 0754123456 1000
```

Uthibitisho wa callback unahitaji backend inayofikika hadharani (Render) na
Firebase Admin service account; bila hivyo oda haihifadhiwi na malipo yanabaki
`PENDING`.

## Release Android

Kabla ya release, badilisha `applicationId`, tengeneza upload keystore, weka
release signing kwenye `android/key.properties`, kisha jenga:

```bash
flutter build appbundle --release
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
