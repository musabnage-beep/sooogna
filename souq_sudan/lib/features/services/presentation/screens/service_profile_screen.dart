import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/share_service.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../domain/entities/service_entity.dart';
import '../providers/services_provider.dart';
import '../widgets/profession_meta.dart';
import 'package:souq_sudan/core/utils/helpers.dart';

class ServiceProfileScreen extends ConsumerWidget {
  final String userId;
  const ServiceProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(serviceByIdProvider(userId));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'مزود الخدمة',
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => ShareService.showShareSheet(
              context,
              url: ShareService.serviceUrl(userId),
              message: 'شاهد ملف مزود الخدمة على سوق السودان',
            ),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(message: Helpers.friendlyError(e)),
        data: (service) {
          if (service == null) {
            return const Center(child: Text('لم يتم العثور على مزود الخدمة'));
          }
          return _ServiceBody(service: service);
        },
      ),
    );
  }
}

class _ServiceBody extends StatelessWidget {
  final ServiceProfile service;
  const _ServiceBody({required this.service});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.background,
              child: service.profileImage != null
                  ? ClipOval(
                      child: CachedImageWidget(
                        imageUrl: service.profileImage,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(ProfessionMeta.iconFor(service.profession),
                      size: 32, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(service.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      if (service.verifiedStatus.isVerified) ...[
                        const SizedBox(width: 6),
                        VerifiedBadge(status: service.verifiedStatus, size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(ProfessionMeta.nameFor(service.profession),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Text(service.city,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, size: 16, color: AppColors.gold),
                      const SizedBox(width: 2),
                      Text(
                        service.ratingCount == 0
                            ? 'جديد'
                            : '${service.rating.toStringAsFixed(1)} (${service.ratingCount})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (service.description.isNotEmpty) ...[
          Text('نبذة', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(service.description),
          const SizedBox(height: 16),
        ],
        if (service.portfolioImages.isNotEmpty) ...[
          Text('معرض الأعمال', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: service.portfolioImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => CachedImageWidget(
                imageUrl: service.portfolioImages[i],
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            if (service.whatsapp != null && service.whatsapp!.isNotEmpty)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => ShareService.contactWhatsApp(service.whatsapp!,
                      text: 'مرحباً، شاهدت خدماتك على سوق السودان'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366)),
                  icon: const Icon(Icons.chat),
                  label: const Text('واتساب'),
                ),
              ),
            if (service.whatsapp != null &&
                service.whatsapp!.isNotEmpty &&
                service.phone != null &&
                service.phone!.isNotEmpty)
              const SizedBox(width: 12),
            if (service.phone != null && service.phone!.isNotEmpty)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ShareService.dialPhone(service.phone!),
                  icon: const Icon(Icons.call),
                  label: const Text('اتصال'),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
