PLACEHOLDER - REQUIRES REAL CREDENTIALS

This file must be replaced with an actual Firebase Admin Service Account JSON.

TO GET THE REAL FILE:
1. Go to Firebase Console: https://console.firebase.google.com/
2. Select project: kibubu-981a0
3. Go to Project Settings (gear icon) → Service Accounts
4. Click "Generate New Private Key"
5. A JSON file will download
6. Rename it to "service-account.json" (NOT firebase-admin.json)
7. Place it in the server/ directory: server/service-account.json

Then update server/.env:
  GOOGLE_APPLICATION_CREDENTIALS=./service-account.json

SECURITY WARNING:
- NEVER commit this file to Git (it's in .gitignore)
- NEVER share this file
- NEVER put it in the Flutter client code
- This file should ONLY be used by the backend server (Node.js)

THIS FILE (firebase-admin.json) IS NOT USED.
Use service-account.json instead.
