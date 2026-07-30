let admin;
try {
  admin = require('firebase-admin');
} catch (e) {
  admin = {};
}

const { initializeApp, cert, getApps } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');

try {
  const serviceAccount = require('./firebase-service-account.json');

  if (!getApps().length) {
    initializeApp({
      credential: cert(serviceAccount)
    });
  }

  // Attach messaging helper to admin object for legacy callers
  admin.messaging = () => getMessaging();

  console.log('✅ Firebase Admin SDK initialized successfully');
} catch (error) {
  console.error('❌ Firebase Admin SDK failed to initialize:', error.message);
}

module.exports = admin;
