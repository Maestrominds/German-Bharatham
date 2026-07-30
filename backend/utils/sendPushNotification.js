const admin = require('../config/firebase');

/**
 * Sends a push notification using Firebase Cloud Messaging (FCM)
 * @param {string} fcmToken - The FCM token of the recipient device
 * @param {string} title - The notification title
 * @param {string} body - The notification body/message
 * @param {Object} data - Optional extra data payload
 */
const sendPushNotification = async (fcmToken, title, body, data = {}) => {
  if (!fcmToken) {
    console.warn('⚠️ [PUSH NOTIFICATION] No FCM token provided, skipping push.');
    return false;
  }

  // Ensure all data values are strings (FCM requirement)
  const stringifiedData = {};
  for (const key in data) {
    if (data[key] !== null && data[key] !== undefined) {
      stringifiedData[key] = String(data[key]);
    }
  }

  const message = {
    notification: {
      title,
      body,
    },
    data: stringifiedData,
    token: fcmToken,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`✅ [PUSH NOTIFICATION] Successfully sent message:`, response);
    return true;
  } catch (error) {
    console.error(`❌ [PUSH NOTIFICATION] Error sending message:`, error.message);
    return false;
  }
};

module.exports = sendPushNotification;
