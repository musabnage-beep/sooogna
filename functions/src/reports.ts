import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { pushToUser } from './fcm';

/**
 * Notifies every admin user whenever a new report is filed.
 */
export const onReportCreated = onDocumentCreated(
  { document: 'reports/{reportId}', region: 'us-central1' },
  async (event) => {
    const report = event.data?.data();
    if (!report) return;

    const db = getFirestore();
    const admins = await db
      .collection('users')
      .where('role', '==', 'admin')
      .where('isBanned', '==', false)
      .get();

    const reporterName = (report.reporterName as string | undefined) ?? 'مستخدم';
    const targetType = (report.targetType as string | undefined) ?? 'user';
    const reason = (report.reason as string | undefined) ?? '';
    const body = `${reporterName} أبلغ عن ${targetType === 'ad' ? 'إعلان' : 'مستخدم'}: ${reason.substring(0, 80)}`;

    await Promise.all(
      admins.docs.map((d) =>
        pushToUser({
          userId: d.id,
          type: 'report',
          title: 'بلاغ جديد',
          body,
          targetId: event.params.reportId as string,
        }),
      ),
    );
  },
);
