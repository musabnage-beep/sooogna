import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final int? reviewCount;
  final bool interactive;
  final ValueChanged<int>? onRatingChanged;
  final bool showLabel;

  const RatingWidget({
    super.key,
    required this.rating,
    this.size = 18,
    this.color = AppColors.gold,
    this.reviewCount,
    this.interactive = false,
    this.onRatingChanged,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++) _buildStar(i),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (reviewCount != null) ...[
            const SizedBox(width: 4),
            Text(
              '($reviewCount)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildStar(int index) {
    IconData icon;
    if (rating >= index) {
      icon = Icons.star_rounded;
    } else if (rating >= index - 0.5) {
      icon = Icons.star_half_rounded;
    } else {
      icon = Icons.star_outline_rounded;
    }

    final iconWidget = Icon(icon, color: color, size: size);

    if (interactive && onRatingChanged != null) {
      return InkResponse(
        onTap: () => onRatingChanged!(index),
        radius: size,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: iconWidget,
        ),
      );
    }
    return iconWidget;
  }
}
