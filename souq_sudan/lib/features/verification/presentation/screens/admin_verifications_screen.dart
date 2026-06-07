import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/verification_request.dart';
import '../providers/verification_provider.dart';
import 'package:souq_sudan/core/utils/helpers.dart';

class AdminVerificationsScreen extends ConsumerWidget {
  const AdminVerificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingVerificationsProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'طلبات التوثيق'),
      body: pending.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text(Helpers.friendlyError(e))),
        data: (requests) {
          if (requests.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.verified_user_outlined,
              message: 'لا توجد طلبات توثيق معلقة',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _RequestCard(request: requests[i]),
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final VerificationRequest request;
  const _RequestCard({required this.request});

  Future<void> _act(BuildContext context, WidgetRef ref, bool approve) async {
    final notifier = ref.read(verificationNotifierProvider.notifier);
    final ok = approve
        ? await notifier.approve(
            userId: request.userId,
            grantedStatus: request.requestedStatus.value,
          )
        : await notifier.reject(userId: request.userId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (approve ? 'تم قبول الطلب' : 'تم رفض الطلب')
            : 'تعذر تنفيذ العملية'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(request.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('مطلوب: ${request.requestedStatus.arabicLabel}'),
            ),
            if (request.idImageUrl != null && request.idImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedImageWidget(
                  imageUrl: request.idImageUrl,
                  height: 180,
                  width: double.infinity,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _act(context, ref, true),
                    icon: const Icon(Icons.check),
                    label: const Text('قبول'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _act(context, ref, false),
                    icon: const Icon(Icons.close, color: AppColors.error),
                    label: const Text('رفض',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
