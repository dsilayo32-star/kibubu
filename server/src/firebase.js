'use strict';

const fs = require('fs');
const path = require('path');

let admin = null;
try {
  admin = require('firebase-admin');
} catch {
  // firebase-admin module optional
}

let firestore = null;
let firebaseInitialized = false;

/**
 * Builds the ordered list of candidate service-account paths to try.
 */
function credentialCandidates() {
  const envCredPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  return [
    envCredPath,
    envCredPath ? path.resolve(__dirname, '..', envCredPath) : null,
    path.resolve(__dirname, '../firebase-admin.json'),
    path.resolve(__dirname, '../service-account.json'),
  ].filter(Boolean);
}

/**
 * Returns the first candidate path that exists and parses as a service-account
 * JSON document, or null when none qualify.
 */
function findValidCredentialFile(candidates) {
  for (const candidate of candidates) {
    if (!fs.existsSync(candidate)) continue;
    try {
      const parsed = JSON.parse(fs.readFileSync(candidate, 'utf8'));
      if (parsed && (parsed.project_id || parsed.type === 'service_account')) {
        return candidate;
      }
    } catch {
      // Invalid json format in candidate file
    }
  }
  return null;
}

/**
 * Lazily initializes and memoizes the Firestore client.
 * Returns null (and logs a warning) whenever the SDK or credentials are not
 * available, so callers can gracefully skip persistence.
 */
function getFirestore() {
  if (firebaseInitialized) return firestore;
  firebaseInitialized = true;

  if (!admin) {
    console.warn('[Firebase] Skipping DB write - firebase-admin not installed');
    return null;
  }

  const validCredFile = findValidCredentialFile(credentialCandidates());
  if (!validCredFile) {
    console.warn('[Firebase] Skipping DB write - firebase-admin.json not configured');
    return null;
  }

  try {
    if (admin.apps.length === 0) {
      admin.initializeApp({ credential: admin.credential.cert(validCredFile) });
    }
    firestore = admin.firestore();
    return firestore;
  } catch (err) {
    console.warn('[Firebase] Skipping DB write - firebase-admin.json not configured (init error:', err.message, ')');
    return null;
  }
}

/**
 * Firestore server timestamp when admin is available, otherwise a local Date.
 */
function serverTimestamp() {
  return admin ? admin.firestore.FieldValue.serverTimestamp() : new Date();
}

module.exports = { getFirestore, serverTimestamp };
