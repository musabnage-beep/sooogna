import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../domain/entities/service_entity.dart';
import 'profession_meta.dart';

class ServiceCard extends StatelessWidget {
  final ServiceProfile service;

  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => context.push('/services/${service.userId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.background,
                child: service.profileImage != null
                    ? ClipOval(
                        child: CachedImageWidget(
                          imageUrl: service.profileImage,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(ProfessionMeta.iconFor(service.profession),
                        color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            service.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (service.verifiedStatus.isVerified) ...[
                          const SizedBox(width: 4),
                          VerifiedBadge(status: service.verifiedStatus, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ProfessionMeta.nameFor(service.profession),
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(service.city,
                            style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(width: 10),
                        const Icon(Icons.star, size: 14, color: AppColors.gold),
                        const SizedBox(width: 2),
                        Text(
                          service.ratingCount == 0
                              ? 'جديد'
                              : '${service.rating.toStringAsFixed(1)} (${service.ratingCount})',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
