import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/analytics_summary.dart';
import '../providers/analytics_provider.dart';
import 'package:souq_sudan/core/utils/helpers.dart';

class SellerAnalyticsScreen extends ConsumerWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myAnalyticsProvider);
    return Scaffold(
      appBar: const CustomAppBar(title: 'إحصائيات البائع'),
      body: async.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: Helpers.friendlyError(e),
          onRetry: () => ref.invalidate(myAnalyticsProvider),
        ),
        data: (s) => _Body(summary: s),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final AnalyticsSummary summary;
  const _Body({required this.summary});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('نظرة عامة على أداء إعلاناتك',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _StatCard(
              icon: Icons.remove_red_eye_outlined,
              color: AppColors.primary,
              label: 'مشاهدات الإعلانات',
              value: summary.totalViews,
            ),
            _StatCard(
              icon: Icons.forum_outlined,
              color: AppColors.secondary,
              label: 'محاولات التواصل',
              value: summary.totalContacts,
            ),
            _StatCard(
              icon: Icons.favorite_outline,
              color: AppColors.error,
              label: 'حفظ الإعلانات',
              value: summary.totalSaved,
            ),
            _StatCard(
              icon: Icons.person_outline,
              color: AppColors.verifiedBlue,
              label: 'زيارات الملف',
              value: summary.profileVisits,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تُحتسب هذه الإحصائيات عند تفاعل المستخدمين مع إعلاناتك وملفك الشخصي.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int value;
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 22),
          ),
          Text(
            '$value',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
