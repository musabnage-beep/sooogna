import 'package:flutter/material.dart';
import '../enums/app_enums.dart';
import '../theme/app_theme.dart';

/// Small verification badge shown next to user / seller / store names.
///
/// - [VerifiedStatus.verified]  -> blue check
/// - [VerifiedStatus.premium]   -> gold workspace-premium
/// - [VerifiedStatus.unverified]-> renders nothing
class VerifiedBadge extends StatelessWidget {
  final VerifiedStatus status;
  final double size;
  final bool showLabel;

  const VerifiedBadge({
    super.key,
    required this.status,
    this.size = 16,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    if (status == VerifiedStatus.unverified) return const SizedBox.shrink();

    final isPremium = status == VerifiedStatus.premium;
    final color = isPremium ? AppColors.gold : AppColors.verifiedBlue;
    final icon = isPremium ? Icons.workspace_premium : Icons.verified;

    final iconWidget = Icon(icon, size: size, color: color);
    if (!showLabel) return iconWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(width: 4),
        Text(
          status.arabicLabel,
          style: TextStyle(
            fontSize: size * 0.8,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
