import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/ads_provider.dart';
import '../widgets/ad_grid_card.dart';
import '../widgets/filter_bottom_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryCtrl = TextEditingController();
  Timer? _debounce;
  FilterState _filter = const FilterState();
  List<String> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recent = prefs.getStringList(AppConstants.recentSearchesKey) ?? [];
    });
  }

  Future<void> _saveRecent(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current =
        prefs.getStringList(AppConstants.recentSearchesKey) ?? <String>[];
    current.remove(query);
    current.insert(0, query);
    if (current.length > AppConstants.recentSearchesMax) {
      current.removeRange(AppConstants.recentSearchesMax, current.length);
    }
    await prefs.setStringList(AppConstants.recentSearchesKey, current);
    if (mounted) setState(() => _recent = current);
  }

  void _performSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final trimmed = q.trim();
      if (trimmed.isEmpty && _filter.category == null && _filter.location == null) {
        ref.read(searchProvider.notifier).clear();
        return;
      }
      ref.read(searchProvider.notifier).search(
            trimmed,
            category: _filter.category,
            location: _filter.location,
            minPrice: _filter.minPrice,
            maxPrice: _filter.maxPrice,
            sortBy: _filter.sortBy,
          );
      if (trimmed.isNotEmpty) _saveRecent(trimmed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final hasQuery = _queryCtrl.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: TextField(
          controller: _queryCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'ابحث عن إعلان...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: (v) {
            setState(() {});
            _performSearch(v);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () async {
              final f = await FilterBottomSheet.show(context, _filter);
              if (f != null) {
                setState(() => _filter = f);
                _performSearch(_queryCtrl.text);
              }
            },
          ),
        ],
      ),
      body: Builder(
        builder: (_) {
          if (!hasQuery && _filter.category == null && _filter.location == null) {
            return _buildRecentSearches();
          }
          if (state.isLoading) return const LoadingWidget();
          if (state.error != null && state.results.isEmpty) {
            return AppErrorWidget(message: state.error!);
          }
          if (state.results.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.search_off,
              message: 'لم يتم العثور على نتائج',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: state.results.length,
            itemBuilder: (_, i) => AdGridCard(ad: state.results[i]),
          );
        },
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recent.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search,
        message: 'ابدأ البحث عن إعلان',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عمليات البحث الأخيرة',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(AppConstants.recentSearchesKey);
                  if (mounted) setState(() => _recent = []);
                },
                child: const Text('مسح الكل'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _recent.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.history),
              title: Text(_recent[i]),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final list = List<String>.from(_recent);
                  list.removeAt(i);
                  await prefs.setStringList(
                      AppConstants.recentSearchesKey, list);
                  if (mounted) setState(() => _recent = list);
                },
              ),
              onTap: () {
                _queryCtrl.text = _recent[i];
                setState(() {});
                _performSearch(_recent[i]);
              },
            ),
          ),
        ),
      ],
    );
  }
}
