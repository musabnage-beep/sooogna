import 'package:flutter/material.dart';
import '../../../../core/constants/category_filters.dart';
import '../../../../core/l10n/app_locale.dart';

class CategoryFieldsWidget extends StatelessWidget {
  final String? categoryId;
  final Map<String, String> values;
  final ValueChanged<Map<String, String>> onChanged;
  final String langCode;

  const CategoryFieldsWidget({
    super.key,
    required this.categoryId,
    required this.values,
    required this.onChanged,
    this.langCode = 'ar',
  });

  @override
  Widget build(BuildContext context) {
    final fields = CategoryFilters.forCategory(categoryId);
    if (fields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          S.tr('details', langCode),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...fields.map((field) => _buildField(context, field)),
      ],
    );
  }

  Widget _buildField(BuildContext context, Map<String, dynamic> field) {
    final key = field['key'] as String;
    final label = CategoryFilters.labelFor(field, langCode);
    final type = field['type'] as String;

    if (type == 'select') {
      final options = field['options'] as List;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DropdownButtonFormField<String>(
          value: values[key],
          decoration: InputDecoration(labelText: label),
          items: [
            DropdownMenuItem(value: null, child: Text('${S.tr('select', langCode)} $label')),
            ...options.map((o) => DropdownMenuItem(value: o as String, child: Text(o))),
          ],
          onChanged: (v) {
            final updated = Map<String, String>.from(values);
            if (v == null) {
              updated.remove(key);
            } else {
              updated[key] = v;
            }
            onChanged(updated);
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: values[key],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onChanged: (v) {
          final updated = Map<String, String>.from(values);
          if (v.isEmpty) {
            updated.remove(key);
          } else {
            updated[key] = v;
          }
          onChanged(updated);
        },
      ),
    );
  }
}
