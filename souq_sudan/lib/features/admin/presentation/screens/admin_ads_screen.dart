import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/admin_provider.dart';
import '../widgets/ad_review_card.dart';
import 'package:souq_sudan/core/utils/helpers.dart';

class AdminAdsScreen extends ConsumerWidget {
  const AdminAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'إدارة الإعلانات',
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'قيد المراجعة'),
              Tab(text: 'نشطة'),
              Tab(text: 'مرفوضة'),
              Tab(text: 'تم البيع'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AdsTab(status: AdStatus.pending, showActions: true),
            _AdsTab(status: AdStatus.active, showActions: false),
            _AdsTab(status: AdStatus.rejected, showActions: false),
            _AdsTab(status: AdStatus.sold, showActions: false),
          ],
        ),
      ),
    );
  }
}

class _AdsTab extends ConsumerWidget {
  final AdStatus status;
  final bool showActions;

  const _AdsTab({required this.status, required this.showActions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(adminAdsByStatusProvider(status));

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(adminAdsByStatusProvider(status)),
      child: adsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: Helpers.friendlyError(e),
          onRetry: () => ref.invalidate(adminAdsByStatusProvider(status)),
        ),
        data: (ads) {
          if (ads.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.inbox_outlined,
              message: 'لا توجد إعلانات',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ads.length,
            itemBuilder: (_, i) {
              final ad = ads[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AdReviewCard(
                  ad: ad,
                  onTap: () => context.push('/admin/ads/${ad.id}'),
                  onApprove: showActions
                      ? () async {
                          final ok = await ref
                              .read(adminNotifierProvider.notifier)
                              .approveAd(ad.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'تم قبول الإعلان'
                                  : 'تعذر قبول الإعلان'),
                              backgroundColor:
                                  ok ? AppColors.success : AppColors.error,
                            ),
                          );
                          if (ok) {
                            ref.invalidate(
                                adminAdsByStatusProvider(status));
                          }
                        }
                      : null,
                  onReject: showActions
                      ? () async {
                          final reason = await _promptRejection(context);
                          if (reason == null) return;
                          final ok = await ref
                              .read(adminNotifierProvider.notifier)
                              .rejectAd(ad.id, reason);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'تم رفض الإعلان'
                                  : 'تعذر رفض الإعلان'),
                              backgroundColor:
                                  ok ? AppColors.success : AppColors.error,
                            ),
                          );
                          if (ok) {
                            ref.invalidate(
                                adminAdsByStatusProvider(status));
                          }
                        }
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<String?> _promptRejection(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          maxLength: 300,
          decoration: const InputDecoration(
            hintText: 'اذكر سبب رفض الإعلان...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    final reason = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || reason.isEmpty) return null;
    return reason;
  }
}
