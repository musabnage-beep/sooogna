import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_error_widget.dart';
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

class _TypeStyle {
  final IconData icon;
  final Color color;
  final Color bg;
  const _TypeStyle(this.icon, this.color, this.bg);
}

_TypeStyle _styleFor(String type) {
  switch (type) {
    case 'chat':
      return const _TypeStyle(
        Icons.chat_bubble_rounded,
        Color(0xFF2563EB),
        Color(0xFF1E3A5F),
      );
    case 'ad_status':
      return const _TypeStyle(
        Icons.check_circle_rounded,
        Color(0xFF16A34A),
        Color(0xFF1A3D2E),
      );
    case 'review':
      return const _TypeStyle(
        Icons.star_rounded,
        Color(0xFFD97706),
        Color(0xFF3D2E0A),
      );
    case 'system':
      return const _TypeStyle(
        Icons.campaign_rounded,
        Color(0xFF7C3AED),
        Color(0xFF2D1F5E),
      );
    default:
      return const _TypeStyle(
        Icons.notifications_rounded,
        AppColors.textHint,
        AppColors.background,
      );
  }
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final notifsAsync = ref.watch(userNotificationsProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context, null, ref),
        body: const EmptyStateWidget(
          icon: Icons.notifications_off_outlined,
          message: 'يجب تسجيل الدخول لعرض الإشعارات',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, user.id, ref),
      body: notifsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: Helpers.friendlyError(e),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final n = notifs[i];
              return _NotificationCard(
                notification: n,
                onTap: () => _handleTap(context, ref, user.id, n),
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String? userId,
    WidgetRef ref,
  ) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: AppColors.surface,
      centerTitle: true,
      title: const Text(
        'الإشعارات',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      actions: [
        if (userId != null)
          TextButton(
            onPressed: () => _markAllAsRead(ref, userId),
            child: const Text(
              'تحديد الكل',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.divider),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(notification.type);
    final unread = !notification.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: unread
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.18), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colored icon square
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.color, size: 22),
              ),
              const SizedBox(width: 12),
              // Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  unread ? FontWeight.bold : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            margin: const EdgeInsetsDirectional.only(start: 6),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textHint,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Helpers.timeAgo(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
