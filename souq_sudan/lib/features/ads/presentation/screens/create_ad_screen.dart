import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/ad_entity.dart';
import '../providers/ads_provider.dart';
import '../widgets/image_picker_widget.dart';

class CreateAdScreen extends ConsumerStatefulWidget {
  const CreateAdScreen({super.key});

  @override
  ConsumerState<CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends ConsumerState<CreateAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _category;
  String? _state;
  List<File> _images = [];
  bool _phonePrefilled = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (!_phonePrefilled && user != null && _phoneCtrl.text.isEmpty) {
      _phoneCtrl.text = user.phone;
      _phonePrefilled = true;
    }
    final createState = ref.watch(createAdProvider);
    final isDemoGuest = AppConstants.isDemoMode && user == null;

    ref.listen<CreateAdState>(createAdProvider, (prev, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(title: 'إعلان جديد'),
      body: SafeArea(
        // ignore: avoid_unnecessary_containers
        child: isDemoGuest
            ? Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Text(
                      '🔔 وضع الديمو — سيتم نشر الإعلان كزائر مؤقت',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                  Expanded(child: _buildForm(context, createState)),
                ],
              )
            : _buildForm(context, createState),
      ),
    );
  }

  Widget _buildForm(BuildContext context, CreateAdState createState) {
    return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ImagePickerWidget(
                localImages: _images,
                networkImages: const [],
                onLocalImagesChanged: (imgs) => setState(() => _images = imgs),
                onNetworkImageRemoved: (_) {},
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                maxLength: AppConstants.maxAdTitleLength,
                validator: Validators.validateAdTitle,
                decoration: const InputDecoration(
                  labelText: 'عنوان الإعلان *',
                  hintText: 'مثال: سيارة تويوتا 2020 للبيع',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLength: AppConstants.maxAdDescriptionLength,
                validator: Validators.validateAdDescription,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'وصف الإعلان *',
                  hintText: 'اكتب تفاصيل الإعلان...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceCtrl,
                validator: Validators.validatePrice,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                decoration: const InputDecoration(
                  labelText: 'السعر (ج.س) *',
                  hintText: '0 = مجاناً',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                validator: (v) => v == null ? 'يرجى اختيار الفئة' : null,
                decoration: const InputDecoration(labelText: 'الفئة *'),
                items: AppConstants.categories
                    .map((c) => DropdownMenuItem(
                        value: c['id'], child: Text(c['name'] ?? '')))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _state,
                validator: (v) => v == null ? 'يرجى اختيار الولاية' : null,
                decoration: const InputDecoration(labelText: 'الولاية *'),
                items: AppConstants.sudanStates
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _state = v),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cityCtrl,
                validator: (v) =>
                    Validators.validateRequired(v, 'المدينة/الحي'),
                decoration: const InputDecoration(
                  labelText: 'المدينة / الحي *',
                  hintText: 'مثال: الخرطوم بحري',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                validator: Validators.validatePhone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف *',
                  hintText: '+249XXXXXXXXX أو +1XXXXXXXXXX',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: createState.isLoading ? null : _submit,
                child: createState.isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Text(createState.statusMessage ?? 'جاري النشر...'),
                        ],
                      )
                    : const Text('نشر الإعلان'),
              ),
              const SizedBox(height: 16),
              const Text(
                'ملاحظة: يتم مراجعة الإعلانات قبل النشر. الحد الأقصى ${AppConstants.maxAdsPerDay} إعلانات يومياً.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة صورة واحدة على الأقل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    AppUser? user = ref.read(currentUserProvider).value;

    // Demo mode: auto sign-in anonymously so Firebase Storage/Firestore allow the upload
    if (user == null && AppConstants.isDemoMode) {
      try {
        final credential = await FirebaseAuth.instance.signInAnonymously();
        final uid = credential.user?.uid ?? 'demo';
        user = AppUser(
          id: uid,
          name: 'زائر',
          phone: Validators.normalizePhone(_phoneCtrl.text.trim()),
          createdAt: DateTime.now(),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في وضع الديمو: $e'), backgroundColor: AppColors.error),
        );
        return;
      }
    }

    if (user == null) {
      context.go('/login');
      return;
    }

    final ad = Ad(
      id: '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.replaceAll(',', '')),
      category: _category!,
      images: const [],
      userId: user.id,
      userName: user.name,
      userPhone: Validators.normalizePhone(_phoneCtrl.text.trim()),
      location: '$_state - ${_cityCtrl.text.trim()}',
      createdAt: DateTime.now(),
      adState: _state,
      userRating: user.rating,
    );
    final id =
        await ref.read(createAdProvider.notifier).createAd(ad, _images.map((f) => f.path).toList());
    if (!mounted) return;
    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال الإعلان للمراجعة'),
          backgroundColor: AppColors.success,
        ),
      );
      ref.read(createAdProvider.notifier).reset();
      ref.read(homeAdsProvider.notifier).refresh();
      context.pop();
    }
  }
}
