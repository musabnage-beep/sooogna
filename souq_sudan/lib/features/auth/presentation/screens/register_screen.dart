import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String? _state;
  String? _gender;
  bool _agreed = false;

  static const _genders = [
    {'value': 'male', 'label': 'ذكر', 'icon': Icons.male_rounded},
    {'value': 'female', 'label': 'أنثى', 'icon': Icons.female_rounded},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى الموافقة على شروط الاستخدام'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final firebaseUser = ref.read(firebaseAuthProvider).currentUser;
    if (firebaseUser == null) {
      context.go('/login');
      return;
    }

    final notifier = ref.read(authNotifierProvider.notifier);
    final user = await notifier.createUser(
      firebaseUser.uid,
      _nameCtrl.text.trim(),
      firebaseUser.phoneNumber ?? '',
      city: _state,
      gender: _gender,
    );

    if (!mounted) return;
    if (user != null) {
      notifier.saveFcmToken(user.id);
      // Router will automatically navigate to /home once currentUserProvider emits the new user.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final phone = ref.read(firebaseAuthProvider).currentUser?.phoneNumber ?? '';

    ref.listen<AsyncValue<void>>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Helpers.friendlyError(error)),
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Header
                Center(
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_rounded, size: 42, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'أهلاً بك في سوقنا!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  'أكمل بياناتك لإنشاء حسابك',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),

                const SizedBox(height: 32),

                // Phone (read-only, from Firebase Auth)
                if (phone.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            phone,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                        const Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  validator: Validators.validateName,
                  keyboardType: TextInputType.name,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل *',
                    hintText: 'أدخل اسمك كما تريد أن يظهر',
                    prefixIcon: Icon(Icons.badge_rounded),
                  ),
                ),
                const SizedBox(height: 16),

                // State
                DropdownButtonFormField<String>(
                  value: _state,
                  validator: (v) => v == null ? 'يرجى اختيار الولاية' : null,
                  decoration: const InputDecoration(
                    labelText: 'الولاية *',
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                  items: AppConstants.sudanStates
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _state = v),
                ),
                const SizedBox(height: 16),

                // Gender (optional)
                Text('الجنس (اختياري)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: _genders.map((g) {
                    final selected = _gender == g['value'] as String;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _gender = selected ? null : g['value'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? AppColors.primary : AppColors.divider,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(g['icon'] as IconData, color: selected ? AppColors.primary : AppColors.textHint, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  g['label'] as String,
                                  style: TextStyle(
                                    color: selected ? AppColors.primary : AppColors.textSecondary,
                                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Terms agreement
                InkWell(
                  onTap: () => setState(() => _agreed = !_agreed),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            children: [
                              const TextSpan(text: 'أوافق على '),
                              TextSpan(
                                text: 'شروط الاستخدام',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(text: ' و'),
                              TextSpan(
                                text: 'سياسة الخصوصية',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: isLoading ? null : _register,
                    child: isLoading
                        ? const SizedBox(
                            height: 22, width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('إنشاء الحساب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 16),

                // Already have account
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'لديك حساب مسبقاً؟ سجّل دخولك',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
