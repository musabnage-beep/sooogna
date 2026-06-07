import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/verification_provider.dart';
import 'package:souq_sudan/core/utils/helpers.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  VerifiedStatus _requested = VerifiedStatus.verified;
  File? _idImage;

  Future<void> _pickId() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _idImage = File(picked.path));
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final ok = await ref.read(verificationNotifierProvider.notifier).submit(
          userId: user.id,
          userName: user.name,
          requestedStatus: _requested.value,
          idImagePath: _idImage?.path,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلب التوثيق، سيتم مراجعته قريباً'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final err = ref.read(verificationNotifierProvider).error?.toString() ??
          'تعذر إرسال الطلب';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final requestAsync = ref.watch(myVerificationRequestProvider);
    final submitting = ref.watch(verificationNotifierProvider).isLoading;

    return Scaffold(
      appBar: const CustomAppBar(title: 'توثيق الحساب'),
      body: userAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text(Helpers.friendlyError(e))),
        data: (user) {
          if (user == null) return const Center(child: Text('لا يوجد مستخدم'));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Current status card
              Card(
                child: ListTile(
                  leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
                  title: const Text('حالة التوثيق الحالية'),
                  subtitle: Text(user.verifiedStatus.arabicLabel),
                  trailing: VerifiedBadge(status: user.verifiedStatus, size: 22),
                ),
              ),
              const SizedBox(height: 8),

              // Existing request state
              requestAsync.maybeWhen(
                data: (req) {
                  if (req == null) return const SizedBox.shrink();
                  return Card(
                    color: AppColors.background,
                    child: ListTile(
                      leading: const Icon(Icons.assignment_outlined),
                      title: Text('طلبك الحالي: ${req.status.arabicLabel}'),
                      subtitle: req.adminNote != null && req.adminNote!.isNotEmpty
                          ? Text('ملاحظة الإدارة: ${req.adminNote}')
                          : Text('النوع المطلوب: ${req.requestedStatus.arabicLabel}'),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),

              const SizedBox(height: 8),
              const Text(
                'اختر نوع التوثيق المطلوب:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              RadioGroup<VerifiedStatus>(
                groupValue: _requested,
                onChanged: (v) => setState(() => _requested = v!),
                child: const Column(
                  children: [
                    RadioListTile<VerifiedStatus>(
                      value: VerifiedStatus.verified,
                      title: Text('موثق'),
                      subtitle: Text('تأكيد الهوية الأساسي'),
                    ),
                    RadioListTile<VerifiedStatus>(
                      value: VerifiedStatus.premium,
                      title: Text('موثق مميز'),
                      subtitle: Text('للحسابات التجارية والمميزة'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ID upload (optional)
              OutlinedButton.icon(
                onPressed: _pickId,
                icon: const Icon(Icons.badge_outlined),
                label: Text(_idImage == null
                    ? 'إرفاق صورة الهوية (اختياري)'
                    : 'تم اختيار صورة الهوية'),
              ),
              if (_idImage != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_idImage!, height: 160, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'لن تظهر صورة هويتك للعامة، تستخدم فقط للمراجعة من قبل الإدارة.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting ? null : _submit,
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('إرسال طلب التوثيق'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
