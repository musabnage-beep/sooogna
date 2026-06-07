import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/store_entity.dart';
import '../providers/stores_provider.dart';
import 'package:souq_sudan/core/utils/helpers.dart';

class CreateStoreScreen extends ConsumerStatefulWidget {
  const CreateStoreScreen({super.key});

  @override
  ConsumerState<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends ConsumerState<CreateStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String? _city;
  File? _logo;
  File? _banner;
  String? _existingLogo;
  String? _existingBanner;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _whatsappCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _prefill(Store s) {
    _nameCtrl.text = s.name;
    _descCtrl.text = s.description;
    _whatsappCtrl.text = s.whatsapp ?? '';
    _phoneCtrl.text = s.phone ?? '';
    _city = AppConstants.sudanCities.contains(s.city) ? s.city : null;
    _existingLogo = s.logo;
    _existingBanner = s.banner;
    _prefilled = true;
  }

  Future<File?> _pick() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 85,
    );
    return picked != null ? File(picked.path) : null;
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

    final store = Store(
      storeId: user.id,
      ownerId: user.id,
      name: _nameCtrl.text.trim(),
      logo: _existingLogo,
      banner: _existingBanner,
      description: _descCtrl.text.trim(),
      whatsapp: _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      city: _city!,
      createdAt: DateTime.now(),
    );

    final ok = await ref.read(storeFormProvider.notifier).save(
          store,
          newLogoPath: _logo?.path,
          newBannerPath: _banner?.path,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم حفظ المتجر بنجاح'),
            backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    } else {
      final err = ref.read(storeFormProvider).error?.toString() ?? 'تعذر الحفظ';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myStoreAsync = ref.watch(myStoreProvider);
    final saving = ref.watch(storeFormProvider).isLoading;

    return Scaffold(
      appBar: const CustomAppBar(title: 'متجري'),
      body: myStoreAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text(Helpers.friendlyError(e))),
        data: (existing) {
          if (existing != null && !_prefilled) {
            _prefill(existing);
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GestureDetector(
                  onTap: () async {
                    final f = await _pick();
                    if (f != null) setState(() => _banner = f);
                  },
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _banner != null
                        ? Image.file(_banner!, fit: BoxFit.cover)
                        : (_existingBanner != null
                            ? CachedImageWidget(
                                imageUrl: _existingBanner, fit: BoxFit.cover)
                            : const Center(
                                child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      color: AppColors.primary, size: 28),
                                  Text('صورة الغلاف',
                                      style: TextStyle(color: AppColors.primary)),
                                ],
                              ))),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final f = await _pick();
                      if (f != null) setState(() => _logo = f);
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.background,
                      child: _logo != null
                          ? ClipOval(
                              child: Image.file(_logo!,
                                  width: 80, height: 80, fit: BoxFit.cover))
                          : (_existingLogo != null
                              ? ClipOval(
                                  child: CachedImageWidget(
                                      imageUrl: _existingLogo,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover))
                              : const Icon(Icons.storefront,
                                  color: AppColors.primary, size: 28)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المتجر *'),
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'الاسم مطلوب' : null,
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
                  controller: _descCtrl,
                  maxLines: 4,
                  maxLength: AppConstants.maxAdDescriptionLength,
                  decoration: const InputDecoration(
                      labelText: 'وصف المتجر', alignLabelWithHint: true),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _whatsappCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'رقم واتساب', prefixIcon: Icon(Icons.chat)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.call)),
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
                        : const Text('حفظ'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
