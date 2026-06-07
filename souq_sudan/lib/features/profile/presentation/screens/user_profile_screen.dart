import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../ads/presentation/providers/ads_provider.dart';
import '../../../ads/presentation/widgets/ad_grid_card.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/review_card.dart';
import '../widgets/review_dialog.dart';
import 'package:souq_sudan/core/utils/helpers.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _visitCounted = false;

  void _countVisitOnce() {
    if (_visitCounted) return;
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null || currentUser.id == widget.userId) return;
    _visitCounted = true;
    ref.read(analyticsRepositoryProvider).bumpProfileVisits(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;
    final userAsync = ref.watch(userByIdProvider(userId));
    final currentUser = ref.watch(currentUserProvider).value;
    final isSelf = currentUser?.id == userId;
    if (!isSelf) _countVisitOnce();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'الملف الشخصي',
          actions: [
            if (currentUser != null && !isSelf)
              IconButton(
                icon: const Icon(Icons.flag_outlined),
                tooltip: 'إبلاغ',
                onPressed: () => _showReportDialog(context, ref, currentUser),
              ),
          ],
        ),
        body: userAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => AppErrorWidget(
            message: Helpers.friendlyError(e),
            onRetry: () => ref.invalidate(userByIdProvider(userId)),
          ),
          data: (user) {
            if (user == null) {
              return const EmptyStateWidget(
                icon: Icons.person_off_outlined,
                message: 'المستخدم غير موجود',
              );
            }
            return NestedScrollView(
              headerSliverBuilder: (_, __) => [
                SliverToBoxAdapter(
                  child: ProfileHeader(user: user, maskPhone: !isSelf),
                ),
                if (!isSelf)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.phone),
                              label: const Text('اتصال'),
                              onPressed: () => _callUser(user.phone),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.star_border),
                              label: const Text('إضافة تقييم'),
                              onPressed: currentUser == null
                                  ? null
                                  : () async {
                                      if (currentUser.id == user.id) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('لا يمكنك تقييم نفسك'),
                                          ),
                                        );
                                        return;
                                      }
                                      final hasReviewed = await ref.read(
                                        hasUserReviewedProvider((
                                          reviewerId: currentUser.id,
                                          userId: user.id,
                                        )).future,
                                      );
                                      if (!context.mounted) return;
                                      if (hasReviewed) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'لقد قمت بتقييم هذا المستخدم مسبقاً'),
                                          ),
                                        );
                                        return;
                                      }
                                      await ReviewDialog.show(
                                        context,
                                        reviewer: currentUser,
                                        userId: user.id,
                                      );
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: [
                      Tab(text: 'الإعلانات'),
                      Tab(text: 'التقييمات'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _UserAdsTab(userId: userId),
                  _UserReviewsTab(userId: userId),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _callUser(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _showReportDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic currentUser,
  ) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الإبلاغ عن المستخدم'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          maxLength: 300,
          decoration: const InputDecoration(
            hintText: 'اذكر سبب الإبلاغ...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
    if (ok != true) return;
    final reason = reasonCtrl.text.trim();
    if (reason.isEmpty) return;

    final done = await ref.read(profileNotifierProvider.notifier).reportUser(
          reporterId: currentUser.id,
          reporterName: currentUser.name,
          userId: widget.userId,
          reason: reason,
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(done ? 'تم إرسال البلاغ' : 'تعذر إرسال البلاغ'),
        backgroundColor: done ? AppColors.success : AppColors.error,
      ),
    );
  }
}

class _UserAdsTab extends ConsumerWidget {
  final String userId;
  const _UserAdsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(userAdsProvider(userId));
    return adsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(
        message: Helpers.friendlyError(e),
        onRetry: () => ref.invalidate(userAdsProvider(userId)),
      ),
      data: (ads) {
        final activeAds =
            ads.where((a) => a.status == AdStatus.active).toList();
        if (activeAds.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.list_alt,
            message: 'لا توجد إعلانات نشطة',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: activeAds.length,
          itemBuilder: (_, i) => AdGridCard(ad: activeAds[i]),
        );
      },
    );
  }
}

class _UserReviewsTab extends ConsumerWidget {
  final String userId;
  const _UserReviewsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(userReviewsProvider(userId));
    return reviewsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(
        message: Helpers.friendlyError(e),
        onRetry: () => ref.invalidate(userReviewsProvider(userId)),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.rate_review_outlined,
            message: 'لا توجد تقييمات بعد',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => ReviewCard(review: reviews[i]),
        );
      },
    );
  }
}
