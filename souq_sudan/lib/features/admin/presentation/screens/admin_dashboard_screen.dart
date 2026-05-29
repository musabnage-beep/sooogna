import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/admin_provider.dart';
import '../widgets/stat_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'لوحة الإدارة'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: statsAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(dashboardStatsProvider),
          ),
          data: (stats) {
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  children: [
                    StatCard(
                      icon: Icons.people_outline,
                      label: 'المستخدمون',
                      value: '${stats.totalUsers}',
                      onTap: () => context.push('/admin/users'),
                    ),
                    StatCard(
                      icon: Icons.list_alt,
                      label: 'إجمالي الإعلانات',
                      value: '${stats.totalAds}',
                      onTap: () => context.push('/admin/ads'),
                    ),
                    StatCard(
                      icon: Icons.check_circle_outline,
                      label: 'الإعلانات النشطة',
                      value: '${stats.activeAds}',
                      color: AppColors.success,
                    ),
                    StatCard(
                      icon: Icons.hourglass_top,
                      label: 'قيد المراجعة',
                      value: '${stats.pendingAds}',
                      color: AppColors.gold,
                      onTap: () => context.push('/admin/ads'),
                    ),
                    StatCard(
                      icon: Icons.flag_outlined,
                      label: 'بلاغات قيد المعالجة',
                      value: '${stats.unresolvedReports}',
                      color: AppColors.error,
                      onTap: () => context.push('/admin/reports'),
                    ),
                    StatCard(
                      icon: Icons.today,
                      label: 'إعلانات اليوم',
                      value: '${stats.adsPostedToday}',
                      color: AppColors.verifiedBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.people_outline,
                            color: AppColors.primary),
                        title: const Text('إدارة المستخدمين'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.push('/admin/users'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.list_alt,
                            color: AppColors.primary),
                        title: const Text('إدارة الإعلانات'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.push('/admin/ads'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.flag_outlined,
                            color: AppColors.primary),
                        title: const Text('البلاغات'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.push('/admin/reports'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
