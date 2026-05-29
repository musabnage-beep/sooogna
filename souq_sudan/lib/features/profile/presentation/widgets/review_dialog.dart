import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart' show AppUser;
import '../../domain/entities/review_entity.dart';
import '../providers/profile_provider.dart';
import 'rating_widget.dart';

class ReviewDialog extends ConsumerStatefulWidget {
  final AppUser reviewer;
  final String userId;

  const ReviewDialog({
    super.key,
    required this.reviewer,
    required this.userId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required AppUser reviewer,
    required String userId,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ReviewDialog(reviewer: reviewer, userId: userId),
    );
  }

  @override
  ConsumerState<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<ReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تقييم')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    final review = Review(
      id: '',
      reviewerId: widget.reviewer.id,
      reviewerName: widget.reviewer.name,
      reviewerImage: widget.reviewer.profileImage,
      userId: widget.userId,
      rating: _rating.toDouble(),
      comment: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    final ok = await ref.read(profileNotifierProvider.notifier).submitReview(review);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال التقييم بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final err = ref.read(profileNotifierProvider).error?.toString() ?? 'تعذر إرسال التقييم';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('أضف تقييماً'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('قيّم تجربتك'),
              const SizedBox(height: 8),
              Center(
                child: RatingWidget(
                  rating: _rating.toDouble(),
                  size: 36,
                  showLabel: false,
                  interactive: true,
                  onRatingChanged: (v) => setState(() => _rating = v),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 500,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'تعليقك',
                  hintText: 'اكتب تعليقاً عن تجربتك (10 أحرف على الأقل)',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'يرجى إدخال تعليق';
                  if (v.length < 10) return 'يجب أن يكون التعليق 10 أحرف على الأقل';
                  if (v.length > 500) return 'يجب أن لا يتجاوز التعليق 500 حرف';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('إرسال'),
        ),
      ],
    );
  }
}
