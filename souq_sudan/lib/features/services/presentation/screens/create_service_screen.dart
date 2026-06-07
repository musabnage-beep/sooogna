import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../ads/presentation/widgets/image_picker_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/service_entity.dart';
import '../providers/services_provider.dart';
import 'package:souq_sudan/core/utils/helpers.dart';

class CreateServiceScreen extends ConsumerStatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  ConsumerState<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends ConsumerState<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _profession = AppConstants.serviceProfessions.first['id']!;
  String? _city;
  File? _profileImage;
  String? _existingProfileImage;
  List<File> _portfolioLocal = [];
  List<String> _portfolioNetwork = [];
  bool _prefilled = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _whatsappCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _prefill(ServiceProfile s) {
    _nameCtrl.text = s.name;
    _descCtrl.text = s.description;
    _whatsappCtrl.text = s.whatsapp ?? '';
    _phoneCtrl.text = s.phone ?? '';
    _profession = s.profession;
    _city = AppConstants.sudanCities.contains(s.city) ? s.city : null;
    _existingProfileImage = s.profileImage;
    _portfolioNetwork = List<String>.from(s.portfolioImages);
    _prefilled = true;
  }

  Future<void> _pickProfile() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _profileImage = File(picked.path));
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

    final service = ServiceProfile(
      userId: user.id,
      name: _nameCtrl.text.trim(),
      profileImage: _existingProfileImage,
      profession: _profession,
      description: _descCtrl.text.trim(),
      city: _city!,
      portfolioImages: _portfolioNetwork,
      whatsapp: _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    final ok = await ref.read(serviceFormProvider.notifier).save(
          service,
          newProfileImagePath: _profileImage?.path,
          newPortfolioPaths: _portfolioLocal.map((f) => f.path).toList(),
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم حفظ ملف الخدمة بنجاح'),
            backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    } else {
      final err = ref.read(serviceFormProvider).error?.toString() ?? 'تعذر الحفظ';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myServiceAsync = ref.watch(myServiceProvider);
    final saving = ref.watch(serviceFormProvider).isLoading;

    return Scaffold(
      appBar: const CustomAppBar(title: 'ملف الخدمة'),
      body: myServiceAsync.when(
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
                Center(
                  child: GestureDetector(
                    onTap: _pickProfile,
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.background,
                      child: _profileImage != null
                          ? ClipOval(
                              child: Image.file(_profileImage!,
                                  width: 88, height: 88, fit: BoxFit.cover))
                          : (_existingProfileImage != null
                              ? ClipOval(
                                  child: CachedImageWidget(
                                      imageUrl: _existingProfileImage,
                                      width: 88,
                                      height: 88,
                                      fit: BoxFit.cover))
                              : const Icon(Icons.add_a_photo,
                                  color: AppColors.primary, size: 30)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'الاسم *'),
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _profession,
                  decoration: const InputDecoration(labelText: 'المهنة *'),
                  items: [
                    for (final p in AppConstants.serviceProfessions)
                      DropdownMenuItem(value: p['id'], child: Text(p['name']!)),
                  ],
                  onChanged: (v) => setState(() => _profession = v!),
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
                      labelText: 'وصف الخدمة *', alignLabelWithHint: true),
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'الوصف مطلوب (10 أحرف على الأقل)'
                      : null,
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
                const SizedBox(height: 16),
                ImagePickerWidget(
                  localImages: _portfolioLocal,
                  networkImages: _portfolioNetwork,
                  onLocalImagesChanged: (imgs) =>
                      setState(() => _portfolioLocal = imgs),
                  onNetworkImageRemoved: (url) =>
                      setState(() => _portfolioNetwork.remove(url)),
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
