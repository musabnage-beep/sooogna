import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryAdsProvider(widget.categoryId));
    final notifier = ref.read(categoryAdsProvider(widget.categoryId).notifier);

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
      body: RefreshIndicator(
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
            if (state.ads.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.inbox_outlined,
                message: 'لا توجد إعلانات في هذه الفئة',
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
              itemCount: state.ads.length + (state.hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i >= state.ads.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  );
                }
                return AdGridCard(ad: state.ads[i]);
              },
            );
          },
        ),
      ),
    );
  }
}
