import {
  onDocumentCreated,
  onDocumentUpdated,
} from 'firebase-functions/v2/firestore';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { pushToUser } from './fcm';

// Mirror of the client-side limits in app_constants.dart. These are the
// authoritative server-enforced values; the client copies are UX hints only.
const MAX_ADS_PER_DAY = 10;
const AD_POST_COOLDOWN_MS = 2 * 60 * 1000;

/**
 * Pushes the ad owner whenever an ad transitions from `pending` to
 * `active` (approved) or `rejected`.
 */
export const onAdStatusChanged = onDocumentUpdated(
  { document: 'ads/{adId}', region: 'us-central1' },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const beforeStatus = before.status as string | undefined;
    const afterStatus = after.status as string | undefined;
    if (beforeStatus === afterStatus) return;

    const ownerId = after.userId as string | undefined;
    if (!ownerId) return;

    const adId = event.params.adId as string;
    const title = (after.title as string | undefined) ?? 'إعلانك';
    const image = Array.isArray(after.images) && after.images.length > 0
      ? (after.images[0] as string)
      : undefined;

    if (beforeStatus === 'pending' && afterStatus === 'active') {
      await pushToUser({
        userId: ownerId,
        type: 'ad_approved',
        title: 'تم اعتماد إعلانك',
        body: title,
        targetId: adId,
        imageUrl: image,
      });
      return;
    }

    if (beforeStatus === 'pending' && afterStatus === 'rejected') {
      const reason = (after.rejectionReason as string | undefined) ?? '';
      await pushToUser({
        userId: ownerId,
        type: 'ad_rejected',
        title: 'تم رفض إعلانك',
        body: reason.length > 0 ? `${title} — ${reason}` : title,
        targetId: adId,
        imageUrl: image,
      });
    }
  },
);

/**
 * Server-enforced rate limiting on ad creation. The client also checks the
 * daily cap and post cooldown, but a tampered client can bypass those, so this
 * trigger is the authoritative backstop: if a freshly created ad pushes the
 * owner over `MAX_ADS_PER_DAY` in the trailing 24h, or lands within
 * `AD_POST_COOLDOWN_MS` of their previous ad, it is deleted and the owner is
 * notified. New ads are `pending` (not yet public), so deletion is graceful.
 */
export const onAdCreated = onDocumentCreated(
  { document: 'ads/{adId}', region: 'us-central1' },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const ad = snap.data();
    const ownerId = ad.userId as string | undefined;
    if (!ownerId) return;

    const createdAt =
      ad.createdAt instanceof Timestamp ? ad.createdAt : Timestamp.now();
    const adId = event.params.adId as string;

    const db = getFirestore();
    const dayAgo = Timestamp.fromMillis(createdAt.toMillis() - 24 * 60 * 60 * 1000);

    // Owner's ads in the trailing 24h, newest first. Cap the read; we only need
    // to know whether the cap is exceeded and when the previous ad landed.
    const recent = await db
      .collection('ads')
      .where('userId', '==', ownerId)
      .where('createdAt', '>=', dayAgo)
      .orderBy('createdAt', 'desc')
      .limit(MAX_ADS_PER_DAY + 2)
      .get();

    const overDailyCap = recent.size > MAX_ADS_PER_DAY;

    let tooSoon = false;
    for (const d of recent.docs) {
      if (d.id === adId) continue;
      const other = d.data().createdAt;
      if (other instanceof Timestamp) {
        if (createdAt.toMillis() - other.toMillis() < AD_POST_COOLDOWN_MS) {
          tooSoon = true;
        }
        break; // docs are newest-first, so the first non-self doc is the previous ad
      }
    }

    if (!overDailyCap && !tooSoon) return;

    try {
      await snap.ref.delete();
    } catch (e) {
      logger.error('onAdCreated: failed to delete over-quota ad', e);
      return;
    }

    const body = overDailyCap
      ? `تجاوزت الحد اليومي للإعلانات (${MAX_ADS_PER_DAY} إعلانات). حاول غداً.`
      : 'يرجى الانتظار قليلاً قبل نشر إعلان آخر.';
    try {
      await pushToUser({
        userId: ownerId,
        type: 'system',
        title: 'تعذّر نشر الإعلان',
        body,
      });
    } catch (e) {
      logger.error('onAdCreated: notify failed', e);
    }
  },
);
