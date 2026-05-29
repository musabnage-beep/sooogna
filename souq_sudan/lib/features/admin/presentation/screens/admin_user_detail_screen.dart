import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/widgets/profile_header.dart';
import '../providers/admin_provider.dart';

class AdminUserDetailScreen extends ConsumerWidget {
  final String userId;

  const AdminUserDetailScreen({super.key, required this.userId});

  Future<String?> _promptReason(
      BuildContext context, String title, String hint) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          maxLength: 300,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    final reason = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || reason.isEmpty) return null;
    return reason;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(userId));

    return Scaffold(
      appBar: const CustomAppBar(title: 'إدارة المستخدم'),
      body: userAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(userByIdProvider(userId)),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('المستخدم غير موجود'));
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileHeader(user: user, maskPhone: false),
                if (user.isBanned)
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.block, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('المستخدم محظور',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                        if (user.banReason != null) ...[
                          const SizedBox(height: 4),
                          Text('السبب: ${user.banReason}'),
                        ],
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.verified,
                            color: AppColors.verifiedBlue),
                        title: const Text('حساب موثّق'),
                        value: user.isVerified,
                        onChanged: (v) async {
                          final ok = await ref
                              .read(adminNotifierProvider.notifier)
                              .verifyUser(user.id, v);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'تم تحديث حالة التوثيق'
                                  : 'تعذر التحديث'),
                              backgroundColor:
                                  ok ? AppColors.success : AppColors.error,
                            ),
                          );
                        },
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.admin_panel_settings,
                            color: AppColors.gold),
                        title: const Text('صلاحية المسؤول'),
                        value: user.isAdmin,
                        onChanged: (v) async {
                          final confirmed = await ConfirmDialog.show(
                            context,
                            title: v
                                ? 'منح صلاحية الإدارة'
                                : 'إزالة صلاحية الإدارة',
                            message: v
                                ? 'هل تريد منح هذا المستخدم صلاحيات الإدارة؟'
                                : 'هل تريد سحب صلاحيات الإدارة من هذا المستخدم؟',
                            isDestructive: !v,
                          );
                          if (!confirmed) return;
                          final ok = await ref
                              .read(adminNotifierProvider.notifier)
                              .setUserRole(
                                user.id,
                                v ? UserRole.admin : UserRole.user,
                              );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  ok ? 'تم تحديث الصلاحية' : 'تعذر التحديث'),
                              backgroundColor:
                                  ok ? AppColors.success : AppColors.error,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: user.isBanned
                            ? ElevatedButton.icon(
                                icon: const Icon(Icons.lock_open),
                                label: const Text('رفع الحظر'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                ),
                                onPressed: () async {
                                  final ok = await ref
                                      .read(adminNotifierProvider.notifier)
                                      .unbanUser(user.id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          ok ? 'تم رفع الحظر' : 'تعذر التحديث'),
                                      backgroundColor: ok
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  );
                                },
                              )
                            : OutlinedButton.icon(
                                icon: const Icon(Icons.block,
                                    color: AppColors.error),
                                label: const Text('حظر المستخدم',
                                    style: TextStyle(color: AppColors.error)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.error),
                                ),
                                onPressed: () async {
                                  final reason = await _promptReason(
                                    context,
                                    'سبب الحظر',
                                    'اذكر سبب حظر المستخدم...',
                                  );
                                  if (reason == null) return;
                                  final ok = await ref
                                      .read(adminNotifierProvider.notifier)
                                      .banUser(user.id, reason);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          ok ? 'تم حظر المستخدم' : 'تعذر التحديث'),
                                      backgroundColor: ok
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('حذف الحساب والمحتوى'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          onPressed: () async {
                            final confirmed = await ConfirmDialog.show(
                              context,
                              title: 'حذف الحساب نهائياً',
                              message:
                                  'سيتم حذف الحساب وجميع الإعلانات والتقييمات الخاصة به. لا يمكن التراجع.',
                              confirmText: 'حذف نهائي',
                              isDestructive: true,
                            );
                            if (!confirmed) return;
                            final ok = await ref
                                .read(adminNotifierProvider.notifier)
                                .deleteUserWithContent(user.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'تم حذف الحساب'
                                    : 'تعذر حذف الحساب'),
                                backgroundColor: ok
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            );
                            if (ok && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
