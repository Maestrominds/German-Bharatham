const admin = require('firebase-admin');
const path = require('path');

try {
  // We explicitly load the service account from the config directory
  const serviceAccount = require('./firebase-service-account.json');

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });

  console.log('✅ Firebase Admin SDK initialized successfully');
} catch (error) {
  console.error('❌ Firebase Admin SDK failed to initialize:', error.message);
}

module.exports = admin;
