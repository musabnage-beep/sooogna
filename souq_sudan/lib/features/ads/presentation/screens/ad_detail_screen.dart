import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/category_filters.dart';
import '../../../../core/l10n/app_locale.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/seo_meta.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/utils/share_service.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/owner_type_badge.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../favorites/presentation/widgets/save_ad_button.dart';
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
  bool _seoApplied = false;

  @override
  void dispose() {
    SeoMeta.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adAsync = ref.watch(adDetailProvider(widget.adId));
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: adAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: Helpers.friendlyError(e),
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
              ref.read(analyticsRepositoryProvider).bumpViews(ad.userId);
            });
          }
          if (!_seoApplied) {
            _seoApplied = true;
            SeoMeta.set(
              title: '${ad.title} - ${Helpers.formatPrice(ad.price)}',
              description: ad.description,
              imageUrl: ad.images.isNotEmpty ? ad.images.first : null,
              url: ShareService.adUrl(ad.id),
            );
          }
          final isOwner = currentUser?.id == ad.userId;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                surfaceTintColor: AppColors.surface,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                actions: [
                  if (currentUser != null)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: SaveAdButton(
                            ad: ad, color: const Color(0xFFEF4444)),
                      ),
                    ),
                  if (!isOwner && currentUser != null)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: IconButton(
                          icon: const Icon(Icons.flag_outlined,
                              color: AppColors.textPrimary),
                          onPressed: () => _showReportDialog(context, ad),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        icon: const Icon(Icons.share_outlined,
                            color: AppColors.textPrimary),
                        onPressed: () => _shareAd(ad),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: ImageSlider(images: ad.images),
                ),
              ),
              SliverToBoxAdjacent(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          PriceTag(price: ad.price, fontSize: 24),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ad.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OwnerTypeBadge(ownerType: ad.ownerType),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _MetaChip(
                            icon: Icons.location_on_rounded,
                            label: ad.location,
                          ),
                          _MetaChip(
                            icon: Icons.schedule_rounded,
                            label: Helpers.timeAgo(ad.createdAt),
                          ),
                          _MetaChip(
                            icon: Icons.remove_red_eye_rounded,
                            label: '${ad.viewCount}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdjacent(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الوصف',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ad.description,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          height: 1.55,
                        ),
                      ),
                      if (ad.attributes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          S.tr('details', ref.watch(localeProvider).languageCode),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ad.attributes.entries.map((e) {
                            final lang = ref.watch(localeProvider).languageCode;
                            final fields = CategoryFilters.forCategory(ad.category);
                            final field = fields.where((f) => f['key'] == e.key).firstOrNull;
                            final label = field != null ? CategoryFilters.labelFor(field, lang) : e.key;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$label: ${e.value}',
                                style: const TextStyle(fontSize: 12.5, color: AppColors.primary),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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
    final message =
        '${ad.title}\n${Helpers.formatPrice(ad.price)}\n${ad.location}';
    await ShareService.showShareSheet(
      context,
      url: ShareService.adUrl(ad.id),
      message: message,
    );
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
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/user/${user.id}'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          width: 2),
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: CachedImageWidget(
                          imageUrl: user.profileImage,
                          width: 52,
                          height: 52,
                          placeholder: Container(
                            color: AppColors.surfaceLight,
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
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (user.verifiedStatus.isVerified) ...[
                              const SizedBox(width: 4),
                              VerifiedBadge(
                                  status: user.verifiedStatus, size: 16),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.secondary, size: 15),
                            const SizedBox(width: 2),
                            Text(
                              user.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              ' (${user.ratingCount} تقييم)',
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: AppColors.textHint, size: 20),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: const Text(
                    'مراسلة',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    if (currentUser == null) {
                      context.push('/login');
                      return;
                    }
                    ref
                        .read(analyticsRepositoryProvider)
                        .bumpContacts(ad.userId);
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
            ),
            if (ad.userPhone != null && ad.userPhone!.isNotEmpty) ...[
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text(
                      'اتصال',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      ref
                          .read(analyticsRepositoryProvider)
                          .bumpContacts(ad.userId);
                      final uri = Uri.parse('tel:${ad.userPhone}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 50,
                height: 50,
                child: Material(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      ref
                          .read(analyticsRepositoryProvider)
                          .bumpContacts(ad.userId);
                      final phone = ad.userPhone!
                          .replaceAll('+', '')
                          .replaceAll(' ', '');
                      final uri = Uri.parse(
                          'https://wa.me/$phone?text=${Uri.encodeComponent('السلام عليكم، بخصوص إعلان: ${ad.title}')}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Icon(Icons.chat_rounded,
                        color: Colors.white, size: 22),
                  ),
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
          color: AppColors.surface,
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
