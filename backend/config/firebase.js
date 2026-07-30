const admin = require('firebase-admin');

try {
  const serviceAccount = require('./firebase-service-account.json');

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential ? admin.credential.cert(serviceAccount) : require('firebase-admin/app').cert(serviceAccount)
    });
  }

  console.log('✅ Firebase Admin SDK initialized successfully');
} catch (error) {
  console.error('❌ Firebase Admin SDK failed to initialize:', error.message);
}

module.exports = admin;
