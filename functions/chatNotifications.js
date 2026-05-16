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
          console.log(`Seller found through sellers table. Recipient User ID: ${recipientUserId}`);
        } else {
          // [NEW] Fallback: If userId is missing in sellers table, or seller doesn't exist, assume sellerId is the User ID.
          recipientUserId = sellerId;
          console.log(`Used fallback sellerId as User ID. Recipient User ID: ${recipientUserId}`);
        }
      } else {
        // Seller sent the message, recipient is the Buyer.
        recipientUserId = userId;
      }

      if (!recipientUserId) {
        console.warn(`Could not determine recipient for chat ${chatId} — skipping.`);
        return null;
      }

      // 3. Get sender profile for notification title & check if sender blocked recipient
      const senderDoc = await db.collection('users').doc(senderId).get();
      const senderData = senderDoc.data() || {};
      const senderName = senderData.displayName || senderData.name || 'Someone';

      // 4. Get recipient's FCM token using their actual User ID
      const recipientDoc = await db.collection('users').doc(recipientUserId).get();
      if (!recipientDoc.exists) {
        console.warn(`Recipient User ${recipientUserId} doc not found — skipping.`);
        return null;
      }

      const recipientData = recipientDoc.data() || {};
      
      // [NEW] Blocking Check
      const recipientBlocked = recipientData.blockedUsers || [];
      const senderBlocked = senderData.blockedUsers || [];
      if (recipientBlocked.includes(senderId) || senderBlocked.includes(recipientUserId)) {
        console.log(`Notification blocked due to user block status between ${senderId} and ${recipientUserId}.`);
        return null;
      }

      const fcmToken = recipientData.fcmToken;

      // Truncate message text for notification preview
      const previewText = (message.text || '').length > 100
        ? message.text.substring(0, 100) + '…'
        : message.text || 'Sent a message';

      // ═══════════════════════════════════════════════════════════════
      // [PHASE 2] Dynamic Template Engine Subsystem
      // ═══════════════════════════════════════════════════════════════
      let notificationTitle = senderName;
      let notificationBody = previewText;

      try {
        console.log(`Template Engine: Attempting to fetch 'CHAT_MESSAGE' from notification_templates...`);
        const templateDoc = await db.collection('notification_templates').doc('CHAT_MESSAGE').get();
        
        if (templateDoc.exists) {
          const templateData = templateDoc.data();
          // Logging data for debugging (excluding sensitive info if any)
          console.log(`Template Engine: Document found. Structure: ${Object.keys(templateData).join(', ')}`);
          
          const locale = 'en'; 
          const locales = templateData.locales || {};
          const langTemplate = locales[locale] || locales['en'];

          if (langTemplate && (langTemplate.title || langTemplate.body)) {
            const interpolate = (str, data) => {
              if (typeof str !== 'string') return str;
              return str.replace(/\{\{(\w+)\}\}/g, (match, key) => data[key] !== undefined ? data[key] : match);
            };
            
            const templateVars = { senderName, previewText };
            
            if (langTemplate.title) {
              notificationTitle = interpolate(langTemplate.title, templateVars);
            }
            if (langTemplate.body) {
              notificationBody = interpolate(langTemplate.body, templateVars);
            }
            
            console.log(`Template Engine: Successfully applied 'CHAT_MESSAGE' [${locale}]`);
            console.log(`Template Engine: Title -> "${notificationTitle}", Body -> "${notificationBody}"`);
          } else {
            console.warn(`Template Engine: langTemplate for locale '${locale}' is missing or incomplete in CHAT_MESSAGE.`);
            console.log('Available locales:', Object.keys(locales));
          }
        } else {
          console.warn('Template Engine: CHAT_MESSAGE document DOES NOT EXIST in notification_templates collection.');
        }
      } catch (templateErr) {
        console.error('Template Engine CRITICAL Error:', templateErr);
        console.log('Jumping to hardcoded fallback logic.');
      }

      // ═══════════════════════════════════════════════════════════════
      // [PHASE 2] Granular Preference Filters (Safe Parsing)
      // ═══════════════════════════════════════════════════════════════
      const prefs = recipientData.notificationPreferences || {};
      
      // Safe checks using Optional Chaining
      const isGlobalMute = prefs.channels?.push === false;
      const isChatMuted = prefs.categories?.chat?.push === false;

      const shouldSendPush = !isGlobalMute && !isChatMuted;

      if (!shouldSendPush) {
        console.log(`FCM Push blocked by preferences for ${recipientUserId}. GlobalMute: ${isGlobalMute}, ChatMuted: ${isChatMuted}`);
      }

      const expiresDate = new Date();
      expiresDate.setDate(expiresDate.getDate() + 7); // 7-day TTL for chat notifications

      // 5. Send FCM push notification (Blocked if preferences dictate, but log for telemetry)
      if (fcmToken && shouldSendPush) {
        try {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: notificationTitle,
              body: notificationBody,
            },
            data: {
              type: 'chat',
              chatId: chatId,
              senderId: senderId,
              senderName: String(senderName || 'Someone'),
              targetId: senderId,
              sellerId: senderId === sellerId ? sellerId : userId,
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
          console.warn(`FCM send failed for ${recipientUserId}:`, fcmErr.message);
          // Delete token if it's invalid or unregistered
          if (
            fcmErr.code === 'messaging/invalid-registration-token' ||
            fcmErr.code === 'messaging/registration-token-not-registered' ||
            fcmErr.message.includes('not registered') ||
            fcmErr.message.includes('InvalidRegistration')
          ) {
            console.log(`Deleting invalid token for user ${recipientUserId}`);
            await db.collection('users').doc(recipientUserId).update({
              fcmToken: admin.firestore.FieldValue.delete(),
            });
          }
        }
      } else if (!fcmToken) {
        console.log(`No FCM token for recipient ${recipientUserId} — skipping push.`);
      }

      // 6. Save in-app notification for the recipient
      await db.collection('users').doc(recipientUserId).collection('notifications').add({
        title: notificationTitle,
        body: notificationBody,
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
        metadata: {
          senderName: String(senderName || 'Someone'),
        },
      });

      console.log(`Chat notification saved for ${recipientUserId} in chat ${chatId}`);
    } catch (err) {
      console.error(`Error processing chat notification for ${chatId}/${messageId}:`, err);
    }

    return null;
  });
