import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../ads/presentation/providers/ads_provider.dart';
import '../../../ads/presentation/widgets/image_slider.dart';
import '../providers/admin_provider.dart';

class AdminAdReviewScreen extends ConsumerWidget {
  final String adId;

  const AdminAdReviewScreen({super.key, required this.adId});

  Future<String?> _promptRejection(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          maxLength: 300,
          decoration: const InputDecoration(
            hintText: 'اذكر سبب رفض الإعلان...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    final reason = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || reason.isEmpty) return null;
    return reason;
  }

  void _showSnack(BuildContext context, bool ok, String successMsg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? successMsg : 'تعذر تنفيذ الإجراء'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adAsync = ref.watch(adDetailProvider(adId));

    return Scaffold(
      appBar: const CustomAppBar(title: 'مراجعة الإعلان'),
      body: adAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(adDetailProvider(adId)),
        ),
        data: (ad) {
          if (ad == null) {
            return const Center(child: Text('الإعلان غير موجود'));
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ad.images.isNotEmpty)
                  ImageSlider(images: ad.images)
                else
                  Container(
                    height: 220,
                    color: AppColors.background,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_outlined,
                        size: 64, color: AppColors.textHint),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(ad.status).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ad.status.arabicLabel,
                              style: TextStyle(
                                color: _statusColor(ad.status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (ad.isFeatured)
                            const Icon(Icons.star, color: AppColors.gold),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(ad.title,
                          style:
                              Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatPrice(ad.price),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Row(Icons.category_outlined, 'الفئة', ad.category),
                      _Row(Icons.location_on_outlined, 'الموقع',
                          ad.location),
                      _Row(Icons.person_outline, 'البائع',
                          ad.userName ?? '-'),
                      _Row(Icons.phone_outlined, 'الهاتف',
                          ad.userPhone ?? '-'),
                      _Row(Icons.access_time, 'تاريخ النشر',
                          Helpers.formatDate(ad.createdAt)),
                      _Row(Icons.visibility_outlined, 'المشاهدات',
                          '${ad.viewCount}'),
                      const SizedBox(height: 12),
                      const Text('الوصف',
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(ad.description),
                      if (ad.rejectionReason != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'سبب الرفض:',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(ad.rejectionReason!),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (ad.status == AdStatus.pending) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.close),
                                label: const Text('رفض'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(
                                      color: AppColors.error),
                                ),
                                onPressed: () async {
                                  final reason =
                                      await _promptRejection(context);
                                  if (reason == null) return;
                                  final ok = await ref
                                      .read(adminNotifierProvider.notifier)
                                      .rejectAd(ad.id, reason);
                                  if (!context.mounted) return;
                                  _showSnack(
                                      context, ok, 'تم رفض الإعلان');
                                  if (ok) {
                                    ref.invalidate(adDetailProvider(adId));
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('قبول'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                ),
                                onPressed: () async {
                                  final ok = await ref
                                      .read(adminNotifierProvider.notifier)
                                      .approveAd(ad.id);
                                  if (!context.mounted) return;
                                  _showSnack(
                                      context, ok, 'تم قبول الإعلان');
                                  if (ok) {
                                    ref.invalidate(adDetailProvider(adId));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.star_outline,
                            color: AppColors.gold),
                        title: const Text('إعلان مميز'),
                        value: ad.isFeatured,
                        onChanged: (v) async {
                          final ok = await ref
                              .read(adminNotifierProvider.notifier)
                              .featureAd(ad.id, v);
                          if (!context.mounted) return;
                          _showSnack(
                              context, ok, 'تم تحديث حالة التمييز');
                          if (ok) {
                            ref.invalidate(adDetailProvider(adId));
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('حذف الإعلان'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          onPressed: () async {
                            final confirmed = await ConfirmDialog.show(
                              context,
                              title: 'حذف الإعلان',
                              message:
                                  'سيتم حذف الإعلان وجميع صوره نهائياً.',
                              confirmText: 'حذف',
                              isDestructive: true,
                            );
                            if (!confirmed) return;
                            final ok = await ref
                                .read(adminNotifierProvider.notifier)
                                .deleteAdAdmin(ad.id);
                            if (!context.mounted) return;
                            _showSnack(context, ok, 'تم حذف الإعلان');
                            if (ok && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(AdStatus status) {
    switch (status) {
      case AdStatus.active:
        return AppColors.success;
      case AdStatus.pending:
        return AppColors.gold;
      case AdStatus.rejected:
        return AppColors.error;
      case AdStatus.sold:
        return AppColors.verifiedBlue;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  // ignore: unused_element_parameter
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
