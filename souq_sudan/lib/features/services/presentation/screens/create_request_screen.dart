import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/service_request_entity.dart';
import '../providers/service_requests_provider.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();

  String _category = AppConstants.serviceProfessions.first['id']!;
  String? _city;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_city == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المدينة')),
      );
      return;
    }
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final budget = double.tryParse(_budgetCtrl.text.trim());
    final request = ServiceRequest(
      id: '',
      userId: user.id,
      userName: user.name,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      budget: budget,
      city: _city!,
      category: _category,
      status: RequestStatus.open,
      createdAt: DateTime.now(),
    );

    final id = await ref.read(requestActionProvider.notifier).create(request);
    if (!mounted) return;
    if (id != null) {
      ref.read(requestsListProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم نشر طلبك بنجاح'),
            backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    } else {
      final err = ref.read(requestActionProvider).error?.toString() ?? 'تعذر النشر';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(requestActionProvider).isLoading;

    return Scaffold(
      appBar: const CustomAppBar(title: 'اطلب خدمة'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              maxLength: AppConstants.maxAdTitleLength,
              decoration: const InputDecoration(labelText: 'عنوان الطلب *'),
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'العنوان مطلوب' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'نوع الخدمة *'),
              items: [
                for (final p in AppConstants.serviceProfessions)
                  DropdownMenuItem(value: p['id'], child: Text(p['name']!)),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _city,
              decoration: const InputDecoration(labelText: 'المدينة *'),
              items: [
                for (final c in AppConstants.sudanCities)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _city = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'الميزانية (اختياري)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: 'ج.س'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 5,
              maxLength: AppConstants.maxAdDescriptionLength,
              decoration: const InputDecoration(
                  labelText: 'تفاصيل الطلب *', alignLabelWithHint: true),
              validator: (v) => (v == null || v.trim().length < 10)
                  ? 'التفاصيل مطلوبة (10 أحرف على الأقل)'
                  : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _submit,
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('نشر الطلب'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
