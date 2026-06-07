import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/favorites_provider.dart';

class SavedAdsScreen extends ConsumerWidget {
  const SavedAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(0),
        body: const EmptyStateWidget(
          icon: Icons.favorite_border_rounded,
          message: 'سجّل الدخول لحفظ الإعلانات',
        ),
      );
    }

    final savedAsync = ref.watch(savedAdsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: savedAsync.when(
        loading: () => Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(0),
          body: const LoadingWidget(),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(0),
          body: AppErrorWidget(message: Helpers.friendlyError(e)),
        ),
        data: (favorites) {
          if (favorites.isEmpty) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: _buildAppBar(0),
              body: const EmptyStateWidget(
                icon: Icons.favorite_border_rounded,
                message: 'لا توجد إعلانات محفوظة',
              ),
            );
          }
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(favorites.length),
            body: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final fav = favorites[i];
                return _SavedCard(
                  imageUrl: fav.image,
                  title: fav.title,
                  price: fav.price,
                  city: fav.city,
                  onTap: () => context.push('/ads/${fav.adId}'),
                  onRemove: () async {
                    final ok = await ref
                        .read(favoritesNotifierProvider.notifier)
                        .remove(fav.adId);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تعذّر إزالة الإعلان'),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(int count) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: AppColors.surface,
      centerTitle: true,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'المفضلة',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (count > 0)
            Text(
              '$count إعلان محفوظ',
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.divider),
      ),
    );
  }
}

class _SavedCard extends ConsumerWidget {
  final String? imageUrl;
  final String title;
  final double price;
  final String city;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedCard({
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.city,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(favoritesNotifierProvider);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadiusDirectional.horizontal(
                  start: Radius.circular(14),
                ).resolve(TextDirection.rtl),
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: CachedImageWidget(
                    imageUrl: imageUrl,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatPrice(price),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (city.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                city,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textHint,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: IconButton(
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                  tooltip: 'إزالة',
                  onPressed: busy ? null : onRemove,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
