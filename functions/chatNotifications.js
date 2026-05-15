const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

// ═══════════════════════════════════════════════════════════════
// CHAT MESSAGE → PUSH NOTIFICATION
// Triggers when a new message is written to chats/{chatId}/messages/{messageId}.
// Sends an FCM push notification to the OTHER participant (the recipient).
// Also saves an in-app notification document for the recipient.
// ═══════════════════════════════════════════════════════════════
exports.onChatMessageCreated = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const { chatId, messageId } = context.params;
    const senderId = message.senderId;

    if (!senderId) {
      console.warn(`Message ${messageId} in chat ${chatId} has no senderId — skipping.`);
      return null;
    }

    try {
      // 1. Read the parent chat document to identify participants
      const chatDoc = await db.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        console.warn(`Chat ${chatId} not found — skipping notification.`);
        return null;
      }

      const chatData = chatDoc.data();
      const participants = chatData.participants || [];
      const userId = chatData.userId;   // buyer
      const sellerId = chatData.sellerId; // seller

      // 2. Determine the recipient user ID
      let recipientUserId;

      if (senderId === userId) {
        // Buyer sent the message, recipient is the Seller.
        // We need the Seller's actual User ID, which is stored in their seller document.
        const sellerDoc = await db.collection('sellers').doc(sellerId).get();
        if (sellerDoc.exists && sellerDoc.data().userId) {
          recipientUserId = sellerDoc.data().userId;
        } else {
          console.warn(`Seller document ${sellerId} not found or missing userId — skipping.`);
          return null;
        }
      } else {
        // Seller sent the message, recipient is the Buyer.
        recipientUserId = userId;
      }

      if (!recipientUserId) {
        console.warn(`Could not determine recipient for chat ${chatId} — skipping.`);
        return null;
      }

      // 3. Get sender profile for notification title
      const senderDoc = await db.collection('users').doc(senderId).get();
      const senderName = senderDoc.exists
        ? senderDoc.data().displayName || senderDoc.data().name || 'Someone'
        : 'Someone';

      // 4. Get recipient's FCM token using their actual User ID
      const recipientDoc = await db.collection('users').doc(recipientUserId).get();
      if (!recipientDoc.exists) {
        console.warn(`Recipient User ${recipientUserId} doc not found — skipping.`);
        return null;
      }

      const recipientData = recipientDoc.data();
      const fcmToken = recipientData.fcmToken;

      // Truncate message text for notification preview
      const previewText = (message.text || '').length > 100
        ? message.text.substring(0, 100) + '…'
        : message.text || 'Sent a message';

      const expiresDate = new Date();
      expiresDate.setDate(expiresDate.getDate() + 7); // 7-day TTL for chat notifications

      // 5. Send FCM push notification
      if (fcmToken) {
        try {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: senderName,
              body: previewText,
            },
            data: {
              type: 'chat',
              targetId: senderId,
              sellerId: senderId === sellerId ? sellerId : userId,
              chatId: chatId,
              deepLink: `/chat/${senderId}`,
              priority: 'medium',
              level: 'conversational',
              role: senderId === sellerId ? 'seller' : 'buyer',
              status: 'DELIVERED',
              expiresAt: expiresDate.toISOString(),
            },
            android: {
              priority: 'high',
              notification: {
                channelId: 'high_importance_channel',
                sound: 'default',
              },
            },
          });
          console.log(`FCM sent to ${recipientUserId} for chat ${chatId}`);
        } catch (fcmErr) {
          // Token may be stale — log but don't fail the function
          console.warn(`FCM send failed for ${recipientUserId}:`, fcmErr.message);
        }
      } else {
        console.log(`No FCM token for recipient ${recipientUserId} — skipping push.`);
      }

      // 6. Save in-app notification for the recipient
      await db.collection('users').doc(recipientUserId).collection('notifications').add({
        title: senderName,
        body: previewText,
        type: 'chat',
        targetId: senderId,
        sellerId: senderId === sellerId ? sellerId : userId,
        chatId: chatId,
        deepLink: `/chat/${senderId}`,
        priority: 'medium',
        level: 'conversational',
        role: senderId === sellerId ? 'seller' : 'buyer',
        status: 'DELIVERED',
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: expiresDate,
      });

      console.log(`Chat notification saved for ${recipientUserId} in chat ${chatId}`);
    } catch (err) {
      console.error(`Error processing chat notification for ${chatId}/${messageId}:`, err);
    }

    return null;
  });
