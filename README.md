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
flutter test
flutter analyze
```

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
