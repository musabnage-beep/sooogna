import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/ad_entity.dart';
import '../providers/ads_provider.dart';
import '../widgets/image_picker_widget.dart';

class EditAdScreen extends ConsumerStatefulWidget {
  final String adId;
  const EditAdScreen({super.key, required this.adId});

  @override
  ConsumerState<EditAdScreen> createState() => _EditAdScreenState();
}

class _EditAdScreenState extends ConsumerState<EditAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _category;
  String? _state;
  List<File> _newImages = [];
  List<String> _existingImages = [];
  final List<String> _removedImages = [];
  bool _initialized = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _prefill(Ad ad) {
    if (_initialized) return;
    _initialized = true;
    _titleCtrl.text = ad.title;
    _descCtrl.text = ad.description;
    _priceCtrl.text = ad.price.toStringAsFixed(0);
    _phoneCtrl.text = ad.userPhone ?? '';
    _existingImages = List<String>.from(ad.images);
    _category = ad.category;
    final parts = ad.location.split(' - ');
    if (parts.length == 2) {
      _state = AppConstants.sudanStates.contains(parts[0]) ? parts[0] : null;
      _cityCtrl.text = parts[1];
    } else {
      _cityCtrl.text = ad.location;
    }
  }

  @override
  Widget build(BuildContext context) {
    final adAsync = ref.watch(adDetailProvider(widget.adId));
    final createState = ref.watch(createAdProvider);

    ref.listen<CreateAdState>(createAdProvider, (prev, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
        );
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(title: 'تعديل الإعلان'),
      body: adAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(adDetailProvider(widget.adId)),
        ),
        data: (ad) {
          if (ad == null) {
            return const Center(child: Text('الإعلان غير موجود'));
          }
          _prefill(ad);
          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ImagePickerWidget(
                    localImages: _newImages,
                    networkImages: _existingImages,
                    onLocalImagesChanged: (imgs) =>
                        setState(() => _newImages = imgs),
                    onNetworkImageRemoved: (url) => setState(() {
                      _existingImages.remove(url);
                      _removedImages.add(url);
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleCtrl,
                    maxLength: AppConstants.maxAdTitleLength,
                    validator: Validators.validateAdTitle,
                    decoration:
                        const InputDecoration(labelText: 'عنوان الإعلان *'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descCtrl,
                    maxLength: AppConstants.maxAdDescriptionLength,
                    validator: Validators.validateAdDescription,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'وصف الإعلان *',
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
                    decoration:
                        const InputDecoration(labelText: 'السعر (ج.س) *'),
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
                    decoration:
                        const InputDecoration(labelText: 'الولاية *'),
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
                    decoration:
                        const InputDecoration(labelText: 'المدينة / الحي *'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneCtrl,
                    validator: Validators.validatePhone,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration:
                        const InputDecoration(labelText: 'رقم الهاتف *'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: createState.isLoading
                        ? null
                        : () => _submit(ad),
                    child: createState.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('حفظ التعديلات'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(Ad original) async {
    if (!_formKey.currentState!.validate()) return;
    if (_existingImages.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يحتوي الإعلان على صورة واحدة على الأقل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final updated = original.copyWith(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.replaceAll(',', '')),
      category: _category,
      location: '$_state - ${_cityCtrl.text.trim()}',
      adState: _state,
      userPhone: Validators.normalizePhone(_phoneCtrl.text.trim()),
      images: _existingImages,
      updatedAt: DateTime.now(),
    );
    final ok = await ref
        .read(createAdProvider.notifier)
        .updateAd(updated, _newImages.map((f) => f.path).toList(), _removedImages);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ التعديلات'),
          backgroundColor: AppColors.success,
        ),
      );
      ref.read(createAdProvider.notifier).reset();
      ref.invalidate(adDetailProvider(widget.adId));
      ref.read(homeAdsProvider.notifier).refresh();
      context.pop();
    }
  }
}
