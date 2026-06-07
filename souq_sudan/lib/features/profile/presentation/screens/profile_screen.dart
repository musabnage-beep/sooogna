import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/domain/entities/user_entity.dart' show AppUser;
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:souq_sudan/core/utils/helpers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
        title: const Text('حسابي',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: Helpers.friendlyError(e),
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
                    const Text('يجب تسجيل الدخول أولاً',
                        textAlign: TextAlign.center),
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
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileCard(user: user),
                const SizedBox(height: 12),
                _StatsRow(user: user),
                const SizedBox(height: 14),
                _MenuGroup(items: [
                  _MenuItem(
                    icon: Icons.list_alt_rounded,
                    title: 'إعلاناتي',
                    onTap: () => context.push('/my-ads'),
                  ),
                  _MenuItem(
                    icon: Icons.favorite_rounded,
                    title: 'المفضلة',
                    onTap: () => context.go('/saved'),
                  ),
                  _MenuItem(
                    icon: Icons.star_rounded,
                    title: 'تقييماتي',
                    onTap: () => context.push('/seller-analytics'),
                  ),
                ]),
                const SizedBox(height: 10),
                _MenuGroup(items: [
                  _MenuItem(
                    icon: Icons.edit_outlined,
                    title: 'تعديل الحساب',
                    onTap: () => context.push('/edit-profile'),
                  ),
                  _MenuItem(
                    icon: Icons.storefront_outlined,
                    title: 'متجري',
                    onTap: () => context.push('/my-store'),
                  ),
                  _MenuItem(
                    icon: Icons.verified_outlined,
                    title: 'توثيق الحساب',
                    onTap: () => context.push('/verify'),
                  ),
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    title: 'الإعدادات',
                    onTap: () => context.push('/settings'),
                  ),
                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'المساعدة والدعم',
                    onTap: () => context.push('/settings'),
                  ),
                ]),
                if (user.isAdmin) ...[
                  const SizedBox(height: 10),
                  _MenuGroup(items: [
                    _MenuItem(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'لوحة الإدارة',
                      iconColor: AppColors.adminRed,
                      onTap: () => context.push('/admin'),
                    ),
                  ]),
                ],
                const SizedBox(height: 18),
                // Logout button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.20)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
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
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'تسجيل خروج',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

// ── Profile card (avatar + name + verified + contact) ─────────────────────────
class _ProfileCard extends StatelessWidget {
  final AppUser user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: CachedImageWidget(
                    imageUrl: user.profileImage,
                    width: 64,
                    height: 64,
                    placeholder: Container(
                      width: 64, height: 64,
                      color: AppColors.primary.withValues(alpha: 0.10),
                      alignment: Alignment.center,
                      child: Text(
                        Helpers.getInitials(user.name),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (user.isVerified)
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: AppColors.verifiedBlue,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  user.phone,
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 3),
                const Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 12, color: AppColors.textSecondary),
                    SizedBox(width: 2),
                    Text(
                      'الخرطوم',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Verified chip
          if (user.isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 13, color: AppColors.primary),
                  SizedBox(width: 3),
                  Text(
                    'موثوق',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stats row (3 columns) ─────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final AppUser user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatBlock(
              value: '${user.ratingCount}',
              label: 'تقييمات',
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.divider),
          Expanded(
            child: _StatBlock(
              value: '${user.profileVisits}',
              label: 'زيارات',
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.divider),
          Expanded(
            child: _StatBlock(
              value: user.rating.toStringAsFixed(1),
              label: 'التقييم',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  const _StatBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
      ],
    );
  }
}

// ── Menu group (white card) ───────────────────────────────────────────────────
class _MenuGroup extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      children.add(items[i]);
      if (i < items.length - 1) {
        children.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, color: AppColors.divider),
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: ic.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: ic, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_left_rounded,
                  size: 22, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
