import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'حسابي', showBack: false),
      body: userAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off_outlined,
                        size: 64, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    const Text(
                      'يجب تسجيل الدخول أولاً',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('تسجيل الدخول'),
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                ProfileHeader(user: user, maskPhone: false),
                const SizedBox(height: 8),
                _MenuTile(
                  icon: Icons.edit_outlined,
                  title: 'تعديل الحساب',
                  onTap: () => context.push('/edit-profile'),
                ),
                _MenuTile(
                  icon: Icons.list_alt_outlined,
                  title: 'إعلاناتي',
                  onTap: () => context.push('/my-ads'),
                ),
                _MenuTile(
                  icon: Icons.notifications_outlined,
                  title: 'الإشعارات',
                  onTap: () => context.push('/notifications'),
                ),
                _MenuTile(
                  icon: Icons.settings_outlined,
                  title: 'الإعدادات',
                  onTap: () => context.push('/settings'),
                ),
                if (user.isAdmin)
                  _MenuTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'لوحة الإدارة',
                    onTap: () => context.push('/admin'),
                  ),
                const Divider(height: 24),
                _MenuTile(
                  icon: Icons.logout,
                  title: 'تسجيل الخروج',
                  iconColor: AppColors.error,
                  textColor: AppColors.error,
                  onTap: () async {
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'تسجيل الخروج',
                      message: 'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
                      confirmText: 'خروج',
                      isDestructive: true,
                    );
                    if (!confirmed) return;
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_left, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
