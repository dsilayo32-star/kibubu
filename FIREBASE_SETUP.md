# Jinsi ya kuwasha Firebase Cloud Sync (Kibubu)

App inafanya kazi kikamilifu **bila** Firebase — data inahifadhiwa kwenye
simu (SharedPreferences). Firebase inaongeza **backup/restore ya cloud**
kupitia Firestore.

## Project

- Project name: `kibubu`
- Project ID: `kibubu-981a0`

## Hatua

1. Tengeneza project kwenye https://console.firebase.google.com
2. Ongeza app ya Android (package name: `com.example.kibubu` kwa sasa) na/iyo iOS/Web.
3. Pakua `google-services.json` → iweke kwenye `android/app/`.
4. Endesha:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=kibubu-981a0 --platforms=android,web
```

Hii itatengeneza `lib/firebase_options.dart` na kuisajili kwenye platforms zote.

5. `FirebaseService.init()` inapaswa kutumia options hizo:

```dart
import '../firebase_options.dart';

static Future<bool> init() async {
  if (_isReady) return true;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _isReady = true;
  } catch (_) {
    _isReady = false;
  }
  return _isReady;
}
```

6. **Firestore Security Rules** (Console → Firestore → Rules) — ruhusu
   kila mtumiaji kusoma/kuandika doc yake pekee:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

7. Ili kuwasha login ya cloud, unaweza kuunganisha
   `FirebaseAuth.instance.signInAnonymously()` (iweshe Anonymous provider
   kwenye Console → Authentication → Sign-in method).

## Deploy rules

Baada ya kuwasha Firestore, tumia:

```bash
firebase deploy --only firestore:rules --project kibubu-981a0
```

Rules ziko kwenye `firestore.rules`, na project default iko kwenye `.firebaserc`.

## Hali ya sasa

- `FirebaseService.init()` inashindwa kimya-kimya kama config haipo —
  app inaendelea kama local-only.
- `syncToCloud()` inaitwa kila mara `saveGoalData()`/`saveSavingsData()`
  zinapohifadhi — itafanya kazi mara config itakapokamilika.
- `restoreFromCloud()` na vitufe vya backup/restore vipo kwenye Profile.
