import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { pushToUser } from './fcm';

/**
 * Recomputes the rated user's `rating` / `ratingCount` whenever a review
 * is created, updated or deleted. Also pushes a notification on create.
 */
export const onReviewWritten = onDocumentWritten(
  { document: 'reviews/{reviewId}', region: 'us-central1' },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    const userId: string | undefined = after?.userId ?? before?.userId;
    if (!userId) return;

    const db = getFirestore();
    const snap = await db
      .collection('reviews')
      .where('userId', '==', userId)
      .get();

    let total = 0;
    let count = 0;
    snap.forEach((d) => {
      const r = d.data();
      if (typeof r.rating === 'number') {
        total += r.rating;
        count += 1;
      }
    });

    const avg = count > 0 ? Math.round((total / count) * 10) / 10 : 0;

    await db.doc(`users/${userId}`).update({
      rating: avg,
      ratingCount: count,
    });

    // Push on create only
    if (!before && after) {
      try {
        await pushToUser({
          userId,
          type: 'review',
          title: 'تقييم جديد',
          body: `حصلت على تقييم جديد (${after.rating}/5)`,
          targetId: userId,
        });
      } catch (e) {
        logger.error('review push failed', e);
      }
    }
  },
);
