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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _state;
  String? _city;
  String? _gender;
  bool _agreed = false;
  bool _phonePrefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _phoneNormalized() =>
      Validators.normalizePhone(_phoneController.text.trim());

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

    final name = _nameController.text.trim();
    final city = _state != null ? '$_state - ${_city ?? ''}'.trim() : null;
    final notifier = ref.read(authNotifierProvider.notifier);
    final firebaseUser = ref.read(firebaseAuthProvider).currentUser;

    if (firebaseUser != null) {
      // Phone already verified (arrived from the login → OTP flow for a brand
      // new number): create the account immediately.
      final phone = firebaseUser.phoneNumber ?? _phoneNormalized();
      final user = await notifier.createUser(
        firebaseUser.uid,
        name,
        phone,
        city: city,
        gender: _gender,
      );
      if (!mounted) return;
      if (user != null) {
        notifier.saveFcmToken(user.id);
        // Router navigates automatically once currentUserProvider emits.
      }
      return;
    }

    // No verified session yet: stash the details, send an OTP, then verify.
    final phone = _phoneNormalized();
    ref.read(pendingRegistrationProvider.notifier).state = PendingRegistration(
      name: name,
      phone: phone,
      city: city,
      gender: _gender,
    );
    final verificationId = await notifier.sendOtp(phone);
    if (!mounted) return;
    if (verificationId != null) {
      context.push('/otp', extra: verificationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final firebaseUser = ref.read(firebaseAuthProvider).currentUser;

    // When verified already, lock the phone field to the confirmed number.
    if (!_phonePrefilled &&
        firebaseUser?.phoneNumber != null &&
        _phoneController.text.isEmpty) {
      _phoneController.text = firebaseUser!.phoneNumber!;
      _phonePrefilled = true;
    }
    final phoneLocked = firebaseUser?.phoneNumber != null;

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
      appBar: AppBar(
        title: const Text('إنشاء حساب'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        size: 42, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'مرحباً بك في سوق السودان!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'أدخل بياناتك لإنشاء حسابك',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  validator: Validators.validateName,
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.name,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل *',
                    hintText: 'مثال: أحمد محمد',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  validator: Validators.validatePhone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  enabled: !phoneLocked,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف *',
                    hintText: '+249XXXXXXXXX',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _state,
                  isExpanded: true,
                  validator: (v) => v == null ? 'يرجى اختيار الولاية' : null,
                  decoration: const InputDecoration(
                    labelText: 'الولاية *',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  items: AppConstants.sudanStates
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _state = v;
                    _city = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_state),
                  initialValue: _city,
                  isExpanded: true,
                  validator: (v) => v == null ? 'يرجى اختيار المدينة' : null,
                  decoration: const InputDecoration(
                    labelText: 'المدينة *',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  items: AppConstants.citiesForState(_state)
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: _state == null
                      ? null
                      : (v) => setState(() => _city = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'الجنس',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                    DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => setState(() => _agreed = !_agreed),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                            children: [
                              TextSpan(text: 'أوافق على '),
                              TextSpan(
                                text: 'شروط الاستخدام',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: ' و'),
                              TextSpan(
                                text: 'سياسة الخصوصية',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : _register,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(phoneLocked ? 'إنشاء الحساب' : 'إرسال رمز التحقق'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'لديك حساب مسبقاً؟ سجّل دخولك',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
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
