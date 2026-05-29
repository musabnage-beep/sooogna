import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class FilterState {
  final String? category;
  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy;

  const FilterState({
    this.category,
    this.location,
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'newest',
  });

  FilterState copyWith({String? category, String? location, double? minPrice, double? maxPrice, String? sortBy}) {
    return FilterState(
      category: category ?? this.category,
      location: location ?? this.location,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  FilterState reset() => const FilterState();
}

class FilterBottomSheet extends StatefulWidget {
  final FilterState initialFilter;
  final void Function(FilterState) onApply;

  const FilterBottomSheet({super.key, required this.initialFilter, required this.onApply});

  static Future<FilterState?> show(BuildContext context, FilterState current) {
    return showModalBottomSheet<FilterState>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FilterBottomSheet(
        initialFilter: current,
        onApply: (f) => Navigator.pop(ctx, f),
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

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    if (_filter.minPrice != null) _minController.text = _filter.minPrice!.toStringAsFixed(0);
    if (_filter.maxPrice != null) _maxController.text = _filter.maxPrice!.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('تصفية النتائج', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => setState(() {
                    _filter = const FilterState();
                    _minController.clear();
                    _maxController.clear();
                  }),
                  child: const Text('إعادة تعيين'),
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
                    Text('الفئة', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.categories.map((cat) {
                        final isSelected = _filter.category == cat['id'];
                        return FilterChip(
                          label: Text(cat['name'] ?? ''),
                          selected: isSelected,
                          onSelected: (v) => setState(() {
                            _filter = _filter.copyWith(category: v ? cat['id'] : null);
                          }),
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('الموقع', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _filter.location,
                      decoration: const InputDecoration(hintText: 'اختر الولاية'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('الكل')),
                        ...AppConstants.sudanStates.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                      ],
                      onChanged: (v) => setState(() => _filter = _filter.copyWith(location: v)),
                    ),
                    const SizedBox(height: 16),
                    Text('نطاق السعر (ج.س)', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'الحد الأدنى'),
                            onChanged: (v) {
                              final d = double.tryParse(v);
                              _filter = _filter.copyWith(minPrice: d);
                            },
                          ),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
                        Expanded(
                          child: TextFormField(
                            controller: _maxController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'الحد الأقصى'),
                            onChanged: (v) {
                              final d = double.tryParse(v);
                              _filter = _filter.copyWith(maxPrice: d);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('الترتيب', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    RadioGroup<String>(
                      groupValue: _filter.sortBy,
                      onChanged: (v) => setState(() => _filter = _filter.copyWith(sortBy: v)),
                      child: Column(
                        children: {
                          'newest': 'الأحدث أولاً',
                          'oldest': 'الأقدم أولاً',
                          'price_asc': 'السعر: الأقل أولاً',
                          'price_desc': 'السعر: الأعلى أولاً',
                        }.entries.map((e) => RadioListTile<String>(
                          value: e.key,
                          title: Text(e.value),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => widget.onApply(_filter),
              child: const Text('تطبيق'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
