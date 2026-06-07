import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/share_service.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../ads/presentation/widgets/ad_grid_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/store_entity.dart';
import '../providers/stores_provider.dart';
import 'package:souq_sudan/core/utils/helpers.dart';

class StoreScreen extends ConsumerStatefulWidget {
  final String storeId;
  const StoreScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        ref.read(storeProductsProvider(widget.storeId).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = ref.watch(storeByIdProvider(widget.storeId));
    final productsState = ref.watch(storeProductsProvider(widget.storeId));
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: storeAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(message: Helpers.friendlyError(e)),
        data: (store) {
          if (store == null) {
            return const Center(child: Text('لم يتم العثور على المتجر'));
          }
          final isOwner = currentUser != null && currentUser.id == store.ownerId;
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(storeProductsProvider(widget.storeId).notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _header(context, store, isOwner),
                if (productsState.error != null && productsState.products.isEmpty)
                  SliverFillRemaining(
                    child: AppErrorWidget(
                      message: productsState.error!,
                      onRetry: () => ref
                          .read(storeProductsProvider(widget.storeId).notifier)
                          .refresh(),
                    ),
                  )
                else if (!productsState.isLoading &&
                    productsState.products.isEmpty)
                  const SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: Icons.inventory_2_outlined,
                      message: 'لا توجد منتجات في هذا المتجر بعد',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            AdGridCard(ad: productsState.products[index]),
                        childCount: productsState.products.length,
                      ),
                    ),
                  ),
                if (productsState.isLoading && productsState.products.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, Store store, bool isOwner) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: store.banner != null
                    ? CachedImageWidget(imageUrl: store.banner, fit: BoxFit.cover)
                    : Container(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () => ShareService.showShareSheet(
                      context,
                      url: ShareService.storeUrl(store.storeId),
                      message: 'تسوّق من متجر ${store.name} على سوق السودان',
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.background,
                  child: store.logo != null
                      ? ClipOval(
                          child: CachedImageWidget(
                              imageUrl: store.logo,
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover))
                      : const Icon(Icons.storefront,
                          size: 30, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(store.city,
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(width: 12),
                          const Icon(Icons.star, size: 16, color: AppColors.gold),
                          const SizedBox(width: 2),
                          Text(
                            store.ratingCount == 0
                                ? 'جديد'
                                : '${store.rating.toStringAsFixed(1)} (${store.ratingCount})',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.inventory_2_outlined,
                              size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text('${store.productCount}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () => context.push('/my-store'),
                  ),
              ],
            ),
          ),
          if (store.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(store.description),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                if (store.whatsapp != null && store.whatsapp!.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => ShareService.contactWhatsApp(store.whatsapp!,
                          text: 'مرحباً، شاهدت متجرك على سوق السودان'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366)),
                      icon: const Icon(Icons.chat),
                      label: const Text('واتساب'),
                    ),
                  ),
                if (store.whatsapp != null &&
                    store.whatsapp!.isNotEmpty &&
                    store.phone != null &&
                    store.phone!.isNotEmpty)
                  const SizedBox(width: 12),
                if (store.phone != null && store.phone!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ShareService.dialPhone(store.phone!),
                      icon: const Icon(Icons.call),
                      label: const Text('اتصال'),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('المنتجات',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
