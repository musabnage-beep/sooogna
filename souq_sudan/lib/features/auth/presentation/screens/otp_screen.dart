import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/otp_input_field.dart';
import '../../../../core/theme/app_theme.dart';

class OTPScreen extends ConsumerStatefulWidget {
  final String verificationId;
  const OTPScreen({super.key, required this.verificationId});

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final _otpController = TextEditingController();
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رمز مكون من 6 أرقام'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final notifier = ref.read(authNotifierProvider.notifier);
    final success = await notifier.verifyOtp(widget.verificationId, otp);
    if (!mounted) return;

    if (success) {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) {
        context.go('/login');
        return;
      }
      final exists = await notifier.userExists(uid);
      if (!mounted) return;
      if (exists) {
        context.go('/home');
      } else {
        context.go('/register');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<void>>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق من الهاتف'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.sms, size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'أدخل رمز التحقق',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'تم إرسال رمز التحقق إلى هاتفك',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              OtpInputField(controller: _otpController),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _verifyOtp,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('تحقق'),
              ),
              const SizedBox(height: 16),
              Center(
                child: _secondsRemaining > 0
                    ? Text(
                        'إعادة الإرسال بعد $_secondsRemaining ثانية',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : TextButton(
                        onPressed: () {
                          context.pop();
                        },
                        child: const Text('إعادة إرسال الرمز'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
