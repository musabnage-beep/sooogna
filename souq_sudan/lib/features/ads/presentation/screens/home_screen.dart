import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/ads_provider.dart';
import '../widgets/ad_grid_card.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/category_icons.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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
        ref.read(homeAdsProvider.notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeAdsState = ref.watch(homeAdsProvider);
    final featuredAsync = ref.watch(featuredAdsProvider);
    final unreadCount = ref.watch(totalUnreadCountProvider);
    final selectedState = homeAdsState.selectedState;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showStateFilterSheet(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedState ?? 'كل السودان',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                ],
              ),
            ),
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
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(homeAdsProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Demo banner
            if (AppConstants.isDemoMode)
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: AppColors.primary.withValues(alpha: 0.15),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.secondary),
                      SizedBox(width: 6),
                      Text(
                        'نسخة ديمو — 100 إعلان تجريبي | جميع الميزات متاحة للتجربة',
                        style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            // Search bar
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded, color: AppColors.textHint),
                      SizedBox(width: 10),
                      Text('ابحث عن أي شيء...',
                          style: TextStyle(color: AppColors.textHint, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            // Categories section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الأقسام الرئيسية',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () {},
                      child: const Text('المزيد',
                          style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
            // Category icons grid
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: AppConstants.categories.map((cat) {
                    final catId = cat['id'] ?? '';
                    final icon = CategoryIcons.forId(catId);
                    final color = CategoryIcons.colorForId(catId);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/category/$catId');
                      },
                      child: Container(
                        width: 76,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(icon, color: color, size: 28),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat['name'] ?? '',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // State filter chips (when a state is selected)
            if (selectedState != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('إعلانات $selectedState',
                          style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ref.read(homeAdsProvider.notifier).setStateFilter(null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('إلغاء الفلتر',
                              style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Featured ads
            if (selectedState == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      const Text('إعلانات مميزة',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            if (selectedState == null)
              featuredAsync.when(
                data: (featured) {
                  if (featured.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: CarouselSlider(
                        options: CarouselOptions(
                          height: 180,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 4),
                          viewportFraction: 0.88,
                          enableInfiniteScroll: featured.length > 1,
                        ),
                        items: featured.map((ad) {
                          return GestureDetector(
                            onTap: () => context.push('/ads/${ad.id}'),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: CachedImageWidget(
                                      imageUrl: ad.images.isNotEmpty ? ad.images[0] : null,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0, left: 0, right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                                        ),
                                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(ad.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text(Helpers.formatPrice(ad.price),
                                              style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 15)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8, right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star_rounded, size: 13, color: Colors.black87),
                                          SizedBox(width: 2),
                                          Text('مميز', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                                        ],
                                      ),
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text(
                      selectedState != null ? 'إعلانات $selectedState' : 'أحدث الإعلانات',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
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
              SliverFillRemaining(
                child: EmptyStateWidget(
                  icon: Icons.inbox_rounded,
                  message: selectedState != null
                      ? 'لا توجد إعلانات في $selectedState'
                      : 'لا توجد إعلانات حالياً',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
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
            // Loading indicator
            if (homeAdsState.isLoading && homeAdsState.ads.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _showStateFilterSheet(BuildContext context) {
    final states = AppConstants.sudanStatesCities.keys.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('اختر الولاية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.public_rounded, color: AppColors.primary),
              title: const Text('كل السودان'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(homeAdsProvider.notifier).setStateFilter(null);
              },
            ),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: states.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.textSecondary),
                  title: Text(states[i]),
                  trailing: ref.read(homeAdsProvider).selectedState == states[i]
                      ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(homeAdsProvider.notifier).setStateFilter(states[i]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.storefront_rounded, size: 40, color: Colors.white),
                  SizedBox(height: 8),
                  Text('سوق السودان', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('بيع واشتري بأمان', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded, color: AppColors.primary),
              title: const Text('الرئيسية'),
              onTap: () {
                Navigator.pop(context);
                context.go('/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded, color: AppColors.textSecondary),
              title: const Text('حسابي'),
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_rounded, color: AppColors.textSecondary),
              title: const Text('إعلاناتي'),
              onTap: () {
                Navigator.pop(context);
                context.push('/my-ads');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_rounded, color: AppColors.error),
              title: const Text('المفضلة'),
              onTap: () {
                Navigator.pop(context);
                context.go('/saved');
              },
            ),
            const Divider(color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
              title: const Text('عن التطبيق'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
