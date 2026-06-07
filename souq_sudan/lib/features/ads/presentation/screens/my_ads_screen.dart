import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/ad_entity.dart';
import '../providers/ads_provider.dart';
import '../widgets/ad_grid_card.dart';

class MyAdsScreen extends ConsumerWidget {
  const MyAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'إعلاناتي'),
        body: EmptyStateWidget(
          icon: Icons.lock_outline,
          message: 'يرجى تسجيل الدخول لعرض إعلاناتك',
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'إعلاناتي',
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'نشطة'),
              Tab(text: 'قيد المراجعة'),
              Tab(text: 'مباعة'),
              Tab(text: 'مرفوضة'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AdsList(userId: user.id, status: AdStatus.active),
            _AdsList(userId: user.id, status: AdStatus.pending),
            _AdsList(userId: user.id, status: AdStatus.sold),
            _AdsList(userId: user.id, status: AdStatus.rejected),
          ],
        ),
      ),
    );
  }
}

class _AdsList extends ConsumerWidget {
  final String userId;
  final AdStatus status;
  const _AdsList({required this.userId, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(userAdsProvider(userId));
    return adsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(userAdsProvider(userId)),
      ),
      data: (ads) {
        final filtered = ads.where((a) => a.status == status).toList();
        if (filtered.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.inbox_outlined,
            message: 'لا توجد إعلانات في "${status.arabicLabel}"',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userAdsProvider(userId));
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _MyAdCard(ad: filtered[i]),
          ),
        );
      },
    );
  }
}

class _MyAdCard extends ConsumerWidget {
  final Ad ad;
  const _MyAdCard({required this.ad});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        AdGridCard(ad: ad),
        Positioned(
          top: 6,
          left: 6,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _showActions(context, ref),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.more_vert,
                    size: 20, color: AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('تعديل'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/edit-ad/${ad.id}');
              },
            ),
            if (ad.status == AdStatus.active) ...[
              ListTile(
                leading: const Icon(Icons.rocket_launch_outlined, color: AppColors.primary),
                title: const Text('تحديث الإعلان (رفع للأعلى)'),
                subtitle: const Text('يظهر إعلانك في أعلى القائمة', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _bumpAd(context, ref);
                },
              ),
              if (!ad.isFeatured && !ad.featuredRequested)
                ListTile(
                  leading: const Icon(Icons.star_outline, color: AppColors.gold),
                  title: const Text('طلب تمييز الإعلان'),
                  subtitle: const Text('سيتم مراجعة طلبك من الإدارة', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _requestFeatured(context, ref);
                  },
                ),
              if (ad.featuredRequested && !ad.isFeatured)
                const ListTile(
                  leading: Icon(Icons.pending_outlined, color: AppColors.gold),
                  title: Text('طلب التمييز قيد المراجعة'),
                  enabled: false,
                ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('وضع علامة "تم البيع"'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final user = ref.read(currentUserProvider).value;
                  if (user == null) return;
                  await ref.read(adsRepositoryProvider).markAsSold(ad.id, user.id);
                  ref.invalidate(userAdsProvider(user.id));
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('حذف', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: 'حذف الإعلان',
                  message: 'هل أنت متأكد من حذف هذا الإعلان نهائياً؟',
                  isDestructive: true,
                  confirmText: 'حذف',
                );
                if (!confirmed) return;
                final user = ref.read(currentUserProvider).value;
                if (user == null) return;
                final res = await ref.read(adsRepositoryProvider).deleteAd(ad.id, user.id);
                if (!context.mounted) return;
                res.when(
                  success: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم الحذف')),
                    );
                    ref.invalidate(userAdsProvider(user.id));
                  },
                  failure: (m, _) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bumpAd(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'last_bump_time_${ad.id}';
    final last = prefs.getInt(key);
    if (last != null) {
      final diff = DateTime.now().millisecondsSinceEpoch - last;
      if (diff < 24 * 60 * 60 * 1000) {
        final hoursLeft = ((24 * 60 * 60 * 1000 - diff) / 3600000).ceil();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('يمكنك تحديث الإعلان بعد $hoursLeft ساعة')),
        );
        return;
      }
    }
    final res = await ref.read(adsRepositoryProvider).bumpAd(ad.id);
    if (res.isSuccess) {
      await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
    }
    if (!context.mounted) return;
    res.when(
      success: (_) {
        final user = ref.read(currentUserProvider).value;
        if (user != null) ref.invalidate(userAdsProvider(user.id));
        ref.read(homeAdsProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الإعلان للأعلى'), backgroundColor: AppColors.success),
        );
      },
      failure: (m, _) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      },
    );
  }

  Future<void> _requestFeatured(BuildContext context, WidgetRef ref) async {
    final res = await ref.read(adsRepositoryProvider).requestFeatured(ad.id);
    if (!context.mounted) return;
    res.when(
      success: (_) {
        final user = ref.read(currentUserProvider).value;
        if (user != null) ref.invalidate(userAdsProvider(user.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلب التمييز للإدارة'), backgroundColor: AppColors.success),
        );
      },
      failure: (m, _) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      },
    );
  }
}
