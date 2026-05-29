import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { pushToUser } from './fcm';

/**
 * Pushes an FCM to the recipient of a chat message.
 * The sender's device receives nothing.
 */
export const onChatMessageCreated = onDocumentCreated(
  { document: 'chats/{chatId}/messages/{messageId}', region: 'us-central1' },
  async (event) => {
    const msg = event.data?.data();
    if (!msg) return;

    const chatId = event.params.chatId as string;
    const senderId: string | undefined = msg.senderId;
    if (!senderId) return;

    const db = getFirestore();
    const chatSnap = await db.doc(`chats/${chatId}`).get();
    if (!chatSnap.exists) return;

    const chat = chatSnap.data() ?? {};
    const userIds: string[] = Array.isArray(chat.userIds) ? chat.userIds : [];
    const recipientId = userIds.find((id) => id !== senderId);
    if (!recipientId) return;

    let senderName = 'مستخدم';
    try {
      const senderSnap = await db.doc(`users/${senderId}`).get();
      const sd = senderSnap.data();
      if (sd?.name) senderName = sd.name as string;
    } catch (e) {
      logger.warn('failed to load sender for chat push', e);
    }

    const preview: string = typeof msg.text === 'string' && msg.text.length > 0
      ? msg.text
      : (msg.imageUrl ? '📷 صورة' : '...');

    await pushToUser({
      userId: recipientId,
      type: 'chat',
      title: senderName,
      body: preview.length > 120 ? preview.substring(0, 117) + '...' : preview,
      targetId: chatId,
    });
  },
);
