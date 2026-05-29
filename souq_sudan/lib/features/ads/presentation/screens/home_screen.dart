import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/ads_provider.dart';
import '../widgets/ad_grid_card.dart';
import '../widgets/category_chip.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/utils/helpers.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  String? _selectedCategory;
  Object? _lastDoc; // For pagination cursor

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      final state = ref.read(homeAdsProvider);
      if (!state.isLoading && state.hasMore) {
        ref.read(homeAdsProvider.notifier).loadMore(_lastDoc);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeAdsState = ref.watch(homeAdsProvider);
    final featuredAsync = ref.watch(featuredAdsProvider);
    final unreadCount = ref.watch(totalUnreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.storefront, color: Colors.white),
            SizedBox(width: 8),
            Text('سوق السودان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeAdsProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Search bar
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.textHint),
                      const SizedBox(width: 8),
                      Text('ابحث عن بضاعة، جوال، سيارة...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textHint)),
                    ],
                  ),
                ),
              ),
            ),
            // Categories
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: AppConstants.categories.map((cat) {
                    return CategoryChip(
                      category: cat,
                      isSelected: _selectedCategory == cat['id'],
                      onTap: () {
                        if (_selectedCategory == cat['id']) {
                          setState(() => _selectedCategory = null);
                        } else {
                          setState(() => _selectedCategory = cat['id']);
                          context.push('/category/${cat['id']}');
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            // Featured ads banner
            featuredAsync.when(
              data: (featured) {
                if (featured.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: CarouselSlider(
                      options: CarouselOptions(
                        height: 150,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 4),
                        viewportFraction: 0.85,
                        enableInfiniteScroll: featured.length > 1,
                      ),
                      items: featured.map((ad) {
                        return GestureDetector(
                          onTap: () => context.push('/ads/${ad.id}'),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedImageWidget(
                                    imageUrl: ad.images.isNotEmpty ? ad.images[0] : null,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0, left: 0, right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                                      ),
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(ad.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        Text(Helpers.formatPrice(ad.price),
                                            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8, right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('مميز', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            // Ads header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text('أحدث الإعلانات', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            // Ads grid
            if (homeAdsState.error != null && homeAdsState.ads.isEmpty)
              SliverFillRemaining(
                child: AppErrorWidget(
                  message: homeAdsState.error!,
                  onRetry: () => ref.read(homeAdsProvider.notifier).refresh(),
                ),
              )
            else if (!homeAdsState.isLoading && homeAdsState.ads.isEmpty)
              const SliverFillRemaining(
                child: EmptyStateWidget(icon: Icons.inbox, message: 'لا توجد إعلانات حالياً'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < homeAdsState.ads.length) {
                        return AdGridCard(ad: homeAdsState.ads[index]);
                      }
                      return const SizedBox.shrink();
                    },
                    childCount: homeAdsState.ads.length,
                  ),
                ),
              ),
            // Loading more indicator
            if (homeAdsState.isLoading && homeAdsState.ads.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}
