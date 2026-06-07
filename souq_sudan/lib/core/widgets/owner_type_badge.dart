import 'package:flutter/material.dart';

import '../enums/app_enums.dart';
import '../theme/app_theme.dart';

/// Small chip indicating who is posting an ad (Feature 6).
/// Highlights direct owners in green so buyers can avoid brokers.
class OwnerTypeBadge extends StatelessWidget {
  final OwnerType ownerType;

  const OwnerTypeBadge({super.key, required this.ownerType});

  @override
  Widget build(BuildContext context) {
    final isOwner = ownerType == OwnerType.owner;
    final color = isOwner ? AppColors.success : AppColors.textSecondary;
    final icon = switch (ownerType) {
      OwnerType.owner => Icons.verified_user_outlined,
      OwnerType.broker => Icons.handshake_outlined,
      OwnerType.company => Icons.business_outlined,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            ownerType.arabicLabel,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
