const prisma = require('../../../config/prisma');

async function broadcastNotification({
  type,
  title,
  message,
  data = null,
  sender = null,
  senderName = null,
  senderPhoto = null,
  read = false,
}) {
  if (!type) throw new Error('type is required');
  if (!title) throw new Error('title is required');
  if (!message) throw new Error('message is required');

  let postgresInserted = 0;
  try {
    const pgRecipients = await prisma.user.findMany({
      where: { role: 'user', isActive: true },
      select: { id: true, fcmToken: true }
    });
    if (pgRecipients.length) {
      let pgSenderId = null;
      if (sender) {
        const parsed = parseInt(sender);
        if (!isNaN(parsed)) pgSenderId = parsed;
      }
      const pgDocs = pgRecipients.map((u) => ({
        recipientId: u.id,
        senderId: pgSenderId,
        type,
        title,
        message,
        senderName,
        senderPhoto,
        data: data || undefined, // Prisma Json field
        read,
      }));
      await prisma.notification.createMany({ data: pgDocs });
      postgresInserted = pgDocs.length;

      // Extract users with valid FCM tokens
      const fcmTokens = pgRecipients
        .filter(u => u.fcmToken && u.fcmToken.trim().length > 0)
        .map(u => u.fcmToken);

      if (fcmTokens.length > 0) {
        const sendPushNotification = require('../../../utils/sendPushNotification');
        const admin = require('../../../config/firebase');
        
        // FCM limit is 500 tokens per multicast message
        const chunkSize = 500;
        for (let i = 0; i < fcmTokens.length; i += chunkSize) {
          const chunk = fcmTokens.slice(i, i + chunkSize);
          const pushMessage = {
            notification: { title, body: message },
            data: data ? Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])) : {},
            tokens: chunk,
          };
          try {
            await admin.messaging().sendEachForMulticast(pushMessage);
          } catch (pushErr) {
            console.error("Failed to broadcast FCM chunk:", pushErr);
          }
        }
      }
    }
  } catch (err) {
    console.error("Failed to broadcast notification:", err);
  }

  return { inserted: postgresInserted };
}

async function notifyListingActivated({ module, entityId, listingTitle }) {
  const safeTitle = (listingTitle || '').toString().trim();
  const name = safeTitle ? `: ${safeTitle}` : '';

  const pretty = {
    services: 'Service',
    foodgrocery: 'Food & Grocery',
    jobs: 'Job',
    accommodation: 'Accommodation',
  }[module] || 'Listing';

  return broadcastNotification({
    type: 'listing_activated',
    title: `New ${pretty} available`,
    message: `A new ${pretty.toLowerCase()} listing is now active${name}`,
    senderName: 'German Bharatham',
    senderPhoto: null,
    data: {
      module,
      entityId: String(entityId),
    },
    read: false,
  });
}

async function deleteOldNotifications(days = 30) {
  try {
    const expiryDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    const result = await prisma.notification.deleteMany({
      where: {
        createdAt: {
          lt: expiryDate
        }
      }
    });
    console.log(`🧹 [CLEANUP] Deleted ${result.count} notifications older than ${days} days.`);
    return result;
  } catch (err) {
    console.error("❌ [CLEANUP ERROR] Failed to delete old notifications:", err);
  }
}

module.exports = {
  broadcastNotification,
  notifyListingActivated,
  deleteOldNotifications,
};
