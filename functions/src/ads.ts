import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { pushToUser } from './fcm';

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
