import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/category_filters.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/theme/app_theme.dart';

class FilterState {
  final String? category;
  final String? location;
  final String? city;
  final bool directOwnersOnly;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy;
  final Map<String, String> categoryAttributes;

  const FilterState({
    this.category,
    this.location,
    this.city,
    this.directOwnersOnly = false,
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'newest',
    this.categoryAttributes = const {},
  });

  FilterState copyWith({
    String? category,
    String? location,
    String? city,
    bool? directOwnersOnly,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    Map<String, String>? categoryAttributes,
  }) {
    return FilterState(
      category: category ?? this.category,
      location: location ?? this.location,
      city: city ?? this.city,
      directOwnersOnly: directOwnersOnly ?? this.directOwnersOnly,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
      categoryAttributes: categoryAttributes ?? this.categoryAttributes,
    );
  }

  FilterState reset() => const FilterState();
}

class FilterBottomSheet extends StatefulWidget {
  final FilterState initialFilter;
  final void Function(FilterState) onApply;
  final String langCode;

  const FilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
    this.langCode = 'ar',
  });

  static Future<FilterState?> show(BuildContext context, FilterState current, {String langCode = 'ar'}) {
    return showModalBottomSheet<FilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FilterBottomSheet(
        initialFilter: current,
        onApply: (f) => Navigator.pop(ctx, f),
        langCode: langCode,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterState _filter;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final Map<String, TextEditingController> _numControllers = {};

  String get _lang => widget.langCode;
  bool get _isAr => _lang == 'ar';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    if (_filter.minPrice != null) _minController.text = _filter.minPrice!.toStringAsFixed(0);
    if (_filter.maxPrice != null) _maxController.text = _filter.maxPrice!.toStringAsFixed(0);
    for (final entry in _filter.categoryAttributes.entries) {
      final field = CategoryFilters.forCategory(_filter.category).where((f) => f['key'] == entry.key).firstOrNull;
      if (field != null && field['type'] == 'number') {
        _numControllers[entry.key] = TextEditingController(text: entry.value);
      }
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    for (final c in _numControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _setCategory(String? cat) {
    setState(() {
      _filter = FilterState(
        category: cat,
        location: _filter.location,
        city: _filter.city,
        directOwnersOnly: _filter.directOwnersOnly,
        minPrice: _filter.minPrice,
        maxPrice: _filter.maxPrice,
        sortBy: _filter.sortBy,
        categoryAttributes: const {},
      );
      for (final c in _numControllers.values) {
        c.dispose();
      }
      _numControllers.clear();
    });
  }

  void _setAttribute(String key, String? value) {
    final attrs = Map<String, String>.from(_filter.categoryAttributes);
    if (value == null || value.isEmpty) {
      attrs.remove(key);
    } else {
      attrs[key] = value;
    }
    setState(() {
      _filter = _filter.copyWith(categoryAttributes: attrs);
    });
  }

  @override
  Widget build(BuildContext context) {
    final catFields = CategoryFilters.forCategory(_filter.category);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.tr('filter_results', _lang), style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => setState(() {
                    _filter = const FilterState();
                    _minController.clear();
                    _maxController.clear();
                    for (final c in _numControllers.values) {
                      c.clear();
                    }
                  }),
                  child: Text(S.tr('reset', _lang)),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chips
                    Text(S.tr('category', _lang), style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.categories.map((cat) {
                        final isSelected = _filter.category == cat['id'];
                        return FilterChip(
                          label: Text(S.catName(cat['id']!, _lang)),
                          selected: isSelected,
                          onSelected: (v) => _setCategory(v ? cat['id'] : null),
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primary,
                        );
                      }).toList(),
                    ),

                    // Category-specific filters
                    if (catFields.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${S.tr('details', _lang)} — ${S.catName(_filter.category!, _lang)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...catFields.map((field) => _buildCategoryField(field)),
                    ],

                    // Location
                    const SizedBox(height: 16),
                    Text(S.tr('location', _lang), style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _filter.location,
                      decoration: InputDecoration(hintText: S.tr('select_state', _lang)),
                      items: [
                        DropdownMenuItem(value: null, child: Text(S.tr('all', _lang))),
                        ...AppConstants.sudanStates.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                      ],
                      onChanged: (v) => setState(() => _filter = _filter.copyWith(location: v)),
                    ),
                    const SizedBox(height: 16),
                    Text(S.tr('city', _lang), style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _filter.city,
                      decoration: InputDecoration(hintText: S.tr('select_city', _lang)),
                      items: [
                        DropdownMenuItem(value: null, child: Text(S.tr('all', _lang))),
                        ...AppConstants.sudanCities.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                      ],
                      onChanged: (v) => setState(() => _filter = _filter.copyWith(city: v)),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _filter.directOwnersOnly,
                      onChanged: (v) => setState(() => _filter = _filter.copyWith(directOwnersOnly: v)),
                      title: Text(S.tr('direct_owner_only', _lang)),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.primary,
                    ),

                    // Price
                    const SizedBox(height: 16),
                    Text(S.tr('price_range', _lang), style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(hintText: S.tr('min', _lang)),
                            onChanged: (v) {
                              _filter = _filter.copyWith(minPrice: double.tryParse(v));
                            },
                          ),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
                        Expanded(
                          child: TextFormField(
                            controller: _maxController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(hintText: S.tr('max', _lang)),
                            onChanged: (v) {
                              _filter = _filter.copyWith(maxPrice: double.tryParse(v));
                            },
                          ),
                        ),
                      ],
                    ),

                    // Sort
                    const SizedBox(height: 16),
                    Text(S.tr('sort_by', _lang), style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...{
                      'newest': S.tr('newest_first', _lang),
                      'oldest': S.tr('oldest_first', _lang),
                      'price_asc': S.tr('price_low_high', _lang),
                      'price_desc': S.tr('price_high_low', _lang),
                    }.entries.map((e) => RadioListTile<String>(
                      value: e.key,
                      groupValue: _filter.sortBy,
                      onChanged: (v) => setState(() => _filter = _filter.copyWith(sortBy: v)),
                      title: Text(e.value),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    )),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onApply(_filter),
                child: Text(S.tr('apply', _lang)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryField(Map<String, dynamic> field) {
    final key = field['key'] as String;
    final label = CategoryFilters.labelFor(field, _lang);
    final type = field['type'] as String;

    if (type == 'select') {
      final options = field['options'] as List;
      final current = _filter.categoryAttributes[key];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          value: current,
          decoration: InputDecoration(labelText: label),
          items: [
            DropdownMenuItem(value: null, child: Text(S.tr('all', _lang))),
            ...options.map((o) => DropdownMenuItem(value: o as String, child: Text(o))),
          ],
          onChanged: (v) => _setAttribute(key, v),
        ),
      );
    }

    // Number field
    _numControllers.putIfAbsent(key, () => TextEditingController(text: _filter.categoryAttributes[key]));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _numControllers[key],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onChanged: (v) => _setAttribute(key, v),
      ),
    );
  }
}
