import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging, MulticastMessage } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions/v2';

/**
 * Sends an FCM push to every token registered against `userId`.
 * Also writes a mirror notification doc under users/{userId}/notifications
 * so the in-app inbox stays consistent. Invalid tokens are pruned.
 */
export async function pushToUser(opts: {
  userId: string;
  title: string;
  body: string;
  type: 'chat' | 'ad_approved' | 'ad_rejected' | 'review' | 'system' | 'report';
  targetId?: string;
  imageUrl?: string;
}): Promise<void> {
  const db = getFirestore();
  const userRef = db.doc(`users/${opts.userId}`);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    logger.warn(`pushToUser: user ${opts.userId} not found`);
    return;
  }

  const data = userSnap.data() ?? {};
  if (data.isBanned === true) return;

  // 1. Inbox mirror
  await userRef.collection('notifications').add({
    type: opts.type,
    title: opts.title,
    body: opts.body,
    targetId: opts.targetId ?? null,
    imageUrl: opts.imageUrl ?? null,
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  });

  // 2. Push
  const tokens: string[] = Array.isArray(data.fcmTokens) ? data.fcmTokens : [];
  if (tokens.length === 0) return;

  const message: MulticastMessage = {
    tokens,
    notification: {
      title: opts.title,
      body: opts.body,
      ...(opts.imageUrl ? { imageUrl: opts.imageUrl } : {}),
    },
    data: {
      type: opts.type,
      ...(opts.targetId ? { targetId: opts.targetId } : {}),
    },
    android: {
      priority: 'high',
      notification: { channelId: 'souq_sudan_default', sound: 'default' },
    },
    apns: {
      payload: { aps: { sound: 'default', badge: 1 } },
    },
  };

  const resp = await getMessaging().sendEachForMulticast(message);

  // 3. Prune dead tokens
  const dead: string[] = [];
  resp.responses.forEach((r, i) => {
    if (!r.success) {
      const code = r.error?.code ?? '';
      if (
        code === 'messaging/invalid-registration-token' ||
        code === 'messaging/registration-token-not-registered'
      ) {
        dead.push(tokens[i]);
      }
    }
  });
  if (dead.length > 0) {
    await userRef.update({ fcmTokens: FieldValue.arrayRemove(...dead) });
  }
}
