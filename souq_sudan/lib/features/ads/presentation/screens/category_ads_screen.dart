import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/category_filters.dart';
import '../../domain/entities/ad_entity.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/ads_provider.dart';
import '../widgets/ad_grid_card.dart';
import '../widgets/filter_bottom_sheet.dart';

class CategoryAdsScreen extends ConsumerStatefulWidget {
  final String categoryId;
  const CategoryAdsScreen({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryAdsScreen> createState() =>
      _CategoryAdsScreenState();
}

class _CategoryAdsScreenState extends ConsumerState<CategoryAdsScreen> {
  final _scrollCtrl = ScrollController();
  FilterState _filter = const FilterState();
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _filter = FilterState(category: widget.categoryId);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 400) {
      final state = ref.read(categoryAdsProvider(widget.categoryId));
      if (state.hasMore && !state.isLoading) {
        ref
            .read(categoryAdsProvider(widget.categoryId).notifier)
            .loadMore();
      }
    }
  }

  String get _categoryName {
    final cat = AppConstants.categories.firstWhere(
      (c) => c['id'] == widget.categoryId,
      orElse: () => const {'name': 'الفئة'},
    );
    return cat['name'] ?? 'الفئة';
  }

  bool _matchesOption(Ad ad, Map<String, dynamic> field, String option) {
    final attr = ad.attributes[field['key'] as String];
    if (attr != null) return attr == option;
    // Older ads predate structured attributes — fall back to text match.
    return ad.title.contains(option);
  }

  Map<String, dynamic>? _primaryField() {
    final fields = CategoryFilters.forCategory(widget.categoryId);
    for (final f in fields) {
      if (f['type'] == 'select') return f;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryAdsProvider(widget.categoryId));
    final notifier = ref.read(categoryAdsProvider(widget.categoryId).notifier);
    final primaryGroup = _primaryField();

    final visibleAds = (_selectedOption == null || primaryGroup == null)
        ? state.ads
        : state.ads
            .where((a) => _matchesOption(a, primaryGroup, _selectedOption!))
            .toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: _categoryName,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () async {
              final f =
                  await FilterBottomSheet.show(context, _filter);
              if (f != null) {
                setState(() => _filter = f);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (primaryGroup != null)
            _buildChipsRow(primaryGroup),
          Expanded(
            child: RefreshIndicator(
              onRefresh: notifier.refresh,
              child: Builder(
                builder: (_) {
                  if (state.ads.isEmpty && state.isLoading) {
                    return const LoadingWidget();
                  }
                  if (state.error != null && state.ads.isEmpty) {
                    return AppErrorWidget(
                      message: state.error!,
                      onRetry: notifier.refresh,
                    );
                  }
                  if (visibleAds.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.inbox_outlined,
                      message: 'لا توجد إعلانات مطابقة',
                    );
                  }
                  return GridView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: visibleAds.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= visibleAds.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        );
                      }
                      return AdGridCard(ad: visibleAds[i]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipsRow(Map<String, dynamic> group) {
    final options = (group['options'] as List).cast<String>();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: const Text('الكل'),
              selected: _selectedOption == null,
              onSelected: (_) => setState(() => _selectedOption = null),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          ...options.map((o) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(o),
                  selected: _selectedOption == o,
                  onSelected: (v) =>
                      setState(() => _selectedOption = v ? o : null),
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                ),
              )),
        ],
      ),
    );
  }
}
