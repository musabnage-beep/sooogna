import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/services_provider.dart';
import '../widgets/profession_meta.dart';
import '../widgets/service_card.dart';
import 'package:souq_sudan/core/utils/helpers.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  final _scrollController = ScrollController();
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(servicesListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String q) {
    setState(() => _searching = q.trim().length >= 2);
    ref.read(servicesSearchProvider.notifier).search(q);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(servicesListProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'الخدمات والحرفيون',
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: 'قدّم خدماتك',
            onPressed: () => context.push('/create-service'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-service'),
        icon: const Icon(Icons.add_business),
        label: const Text('قدّم خدماتك'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'ابحث عن مزود خدمة...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (!_searching) _professionFilter(state),
          Expanded(
            child: _searching ? _searchResults() : _browseList(state),
          ),
        ],
      ),
    );
  }

  Widget _professionFilter(ServicesListState state) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _filterChip('الكل', state.filter.profession == null, () {
            ref.read(servicesListProvider.notifier).applyFilter(
                ServicesFilter(city: state.filter.city));
          }),
          for (final p in AppConstants.serviceProfessions)
            _filterChip(
              p['name'] ?? '',
              state.filter.profession == p['id'],
              () => ref.read(servicesListProvider.notifier).applyFilter(
                  ServicesFilter(profession: p['id'], city: state.filter.city)),
              icon: ProfessionMeta.iconFor(p['id'] ?? 'other'),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap,
      {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 15), const SizedBox(width: 4)],
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _browseList(ServicesListState state) {
    if (state.isLoading && state.services.isEmpty) {
      return const LoadingWidget();
    }
    if (state.error != null && state.services.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => ref.read(servicesListProvider.notifier).refresh(),
      );
    }
    if (state.services.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.handyman_outlined,
        message: 'لا يوجد مزودو خدمات بعد',
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(servicesListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: state.services.length + (state.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= state.services.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return ServiceCard(service: state.services[i]);
        },
      ),
    );
  }

  Widget _searchResults() {
    final async = ref.watch(servicesSearchProvider);
    return async.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(message: Helpers.friendlyError(e)),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.search_off,
            message: 'لا توجد نتائج',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: list.length,
          itemBuilder: (_, i) => ServiceCard(service: list[i]),
        );
      },
    );
  }
}
