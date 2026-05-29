import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/notification_entity.dart';

final userNotificationsProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(const []);
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(user.id)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) => snap.docs.map(_fromDoc).toList());
});

AppNotification _fromDoc(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>? ?? {};
  final ts = data['createdAt'];
  return AppNotification(
    id: doc.id,
    type: (data['type'] as String?) ?? 'other',
    title: (data['title'] as String?) ?? '',
    body: (data['body'] as String?) ?? '',
    targetId: data['targetId'] as String?,
    createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    isRead: (data['isRead'] as bool?) ?? false,
  );
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAsRead(
    WidgetRef ref,
    String userId,
    String notificationId,
  ) async {
    final firestore = ref.read(firestoreProvider);
    await firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> _markAllAsRead(WidgetRef ref, String userId) async {
    final firestore = ref.read(firestoreProvider);
    final unread = await firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    String userId,
    AppNotification n,
  ) {
    if (!n.isRead) {
      _markAsRead(ref, userId, n.id);
    }
    switch (n.type) {
      case 'chat':
        if (n.targetId != null) context.push('/chat/${n.targetId}');
        break;
      case 'ad_status':
        if (n.targetId != null) context.push('/ads/${n.targetId}');
        break;
      case 'review':
        context.push('/profile');
        break;
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'ad_status':
        return Icons.campaign_outlined;
      case 'review':
        return Icons.star_border;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final notifsAsync = ref.watch(userNotificationsProvider);

    if (user == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'الإشعارات'),
        body: EmptyStateWidget(
          icon: Icons.notifications_off_outlined,
          message: 'يجب تسجيل الدخول لعرض الإشعارات',
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'الإشعارات',
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'تحديد الكل كمقروء',
            onPressed: () => _markAllAsRead(ref, user.id),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(userNotificationsProvider),
        ),
        data: (notifs) {
          if (notifs.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none,
              message: 'لا توجد إشعارات',
            );
          }
          return ListView.separated(
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final n = notifs[i];
              return ListTile(
                onTap: () => _handleTap(context, ref, user.id, n),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconFor(n.type),
                      color: AppColors.primary, size: 20),
                ),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  n.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      Helpers.timeAgo(n.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                    if (!n.isRead) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
