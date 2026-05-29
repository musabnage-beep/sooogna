import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/ad_entity.dart';
import '../providers/ads_provider.dart';
import '../widgets/image_slider.dart';
import '../widgets/price_tag.dart';

class AdDetailScreen extends ConsumerStatefulWidget {
  final String adId;
  const AdDetailScreen({super.key, required this.adId});

  @override
  ConsumerState<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends ConsumerState<AdDetailScreen> {
  bool _viewIncremented = false;

  @override
  Widget build(BuildContext context) {
    final adAsync = ref.watch(adDetailProvider(widget.adId));
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: adAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(adDetailProvider(widget.adId)),
        ),
        data: (ad) {
          if (ad == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text('الإعلان غير موجود'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('رجوع'),
                  ),
                ],
              ),
            );
          }
          if (!_viewIncremented && currentUser?.id != ad.userId) {
            _viewIncremented = true;
            Future.microtask(() {
              ref.read(adsRepositoryProvider).incrementViewCount(ad.id);
            });
          }
          final isOwner = currentUser?.id == ad.userId;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                actions: [
                  if (!isOwner && currentUser != null)
                    IconButton(
                      icon: const Icon(Icons.flag_outlined),
                      onPressed: () => _showReportDialog(context, ad),
                    ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => _shareAd(ad),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: ImageSlider(images: ad.images),
                ),
              ),
              SliverToBoxAdjacent(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          PriceTag(price: ad.price, fontSize: 22),
                          if (ad.status != AdStatus.active)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(ad.status)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ad.status.arabicLabel,
                                style: TextStyle(
                                  color: _statusColor(ad.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ad.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            ad.location,
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.schedule,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            Helpers.timeAgo(ad.createdAt),
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.remove_red_eye_outlined,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${ad.viewCount}',
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdjacent(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الوصف',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        ad.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdjacent(
                child: _SellerCard(userId: ad.userId),
              ),
              const SliverToBoxAdjacent(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      bottomNavigationBar: adAsync.maybeWhen(
        data: (ad) {
          if (ad == null) return const SizedBox.shrink();
          final isOwner = currentUser?.id == ad.userId;
          if (isOwner) {
            return _OwnerActionsBar(ad: ad);
          }
          return _BuyerActionsBar(ad: ad);
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Color _statusColor(AdStatus s) {
    switch (s) {
      case AdStatus.active:
        return AppColors.success;
      case AdStatus.pending:
        return AppColors.secondary;
      case AdStatus.rejected:
        return AppColors.error;
      case AdStatus.sold:
        return AppColors.verifiedBlue;
      case AdStatus.expired:
        return AppColors.textHint;
      case AdStatus.suspended:
        return AppColors.error;
    }
  }

  Future<void> _shareAd(Ad ad) async {
    final text = '${ad.title}\n${Helpers.formatPrice(ad.price)}\n${ad.location}';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showReportDialog(BuildContext context, Ad ad) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الإبلاغ عن الإعلان'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'اذكر سبب الإبلاغ...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null || !mounted) return;
    final ok = await ref.read(profileNotifierProvider.notifier).reportUser(
          reporterId: user.id,
          reporterName: user.name,
          userId: ad.userId,
          reason: 'إعلان: ${ad.title} — $reason',
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم إرسال البلاغ' : 'تعذر إرسال البلاغ'),
      ),
    );
  }
}

class SliverToBoxAdjacent extends StatelessWidget {
  final Widget child;
  const SliverToBoxAdjacent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: child);
  }
}

class _SellerCard extends ConsumerWidget {
  final String userId;
  const _SellerCard({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(userId));
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: userAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('تعذر تحميل بيانات البائع: $e'),
        ),
        data: (user) {
          if (user == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('البائع غير متاح'),
            );
          }
          return InkWell(
            onTap: () => context.push('/user/${user.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CachedImageWidget(
                        imageUrl: user.profileImage,
                        width: 48,
                        height: 48,
                        placeholder: Container(
                          color: AppColors.background,
                          alignment: Alignment.center,
                          child: Text(
                            Helpers.getInitials(user.name),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (user.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified,
                                  color: AppColors.verifiedBlue, size: 16),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: AppColors.gold, size: 14),
                            Text(
                              ' ${user.rating.toStringAsFixed(1)} (${user.ratingCount})',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BuyerActionsBar extends ConsumerWidget {
  final Ad ad;
  const _BuyerActionsBar({required this.ad});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.message_outlined),
                label: const Text('مراسلة'),
                onPressed: currentUser == null
                    ? null
                    : () async {
                        final seller =
                            await ref.read(userByIdProvider(ad.userId).future);
                        if (seller == null || !context.mounted) return;
                        final chatId = await ref
                            .read(chatNotifierProvider.notifier)
                            .createOrGetChat(
                              otherUserId: seller.id,
                              otherUserName: seller.name,
                              otherUserImage: seller.profileImage,
                              adId: ad.id,
                              adTitle: ad.title,
                              adImage: ad.images.isNotEmpty
                                  ? ad.images.first
                                  : null,
                            );
                        if (chatId != null && context.mounted) {
                          context.push('/chat/$chatId');
                        }
                      },
              ),
            ),
            const SizedBox(width: 8),
            if (ad.userPhone != null && ad.userPhone!.isNotEmpty) ...[
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.call),
                  label: const Text('اتصال'),
                  onPressed: () async {
                    final uri = Uri.parse('tel:${ad.userPhone}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(56, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () async {
                    final phone =
                        ad.userPhone!.replaceAll('+', '').replaceAll(' ', '');
                    final uri = Uri.parse(
                        'https://wa.me/$phone?text=${Uri.encodeComponent('السلام عليكم، بخصوص إعلان: ${ad.title}')}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: const Icon(Icons.chat, color: Colors.green),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OwnerActionsBar extends ConsumerWidget {
  final Ad ad;
  const _OwnerActionsBar({required this.ad});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل'),
                onPressed: () => context.push('/edit-ad/${ad.id}'),
              ),
            ),
            const SizedBox(width: 8),
            if (ad.status != AdStatus.sold)
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('تم البيع'),
                  onPressed: () async {
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'تأكيد البيع',
                      message: 'هل تم بيع هذا الإعلان؟',
                    );
                    if (!confirmed) return;
                    final user = ref.read(currentUserProvider).value;
                    if (user == null) return;
                    await ref
                        .read(adsRepositoryProvider)
                        .markAsSold(ad.id, user.id);
                    ref.invalidate(adDetailProvider(ad.id));
                  },
                ),
              ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(56, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () async {
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'حذف الإعلان',
                    message: 'سيتم حذف الإعلان نهائياً. هل أنت متأكد؟',
                    isDestructive: true,
                    confirmText: 'حذف',
                  );
                  if (!confirmed) return;
                  final user = ref.read(currentUserProvider).value;
                  if (user == null) return;
                  final res =
                      await ref.read(adsRepositoryProvider).deleteAd(ad.id, user.id);
                  if (!context.mounted) return;
                  res.when(
                    success: (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حذف الإعلان')),
                      );
                      context.pop();
                    },
                    failure: (msg, _) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg)));
                    },
                  );
                },
                child: const Icon(Icons.delete_outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
