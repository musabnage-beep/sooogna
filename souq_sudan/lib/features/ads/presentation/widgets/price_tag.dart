import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';

class PriceTag extends StatelessWidget {
  final double price;
  final double fontSize;

  const PriceTag({super.key, required this.price, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    return Text(
      Helpers.formatPrice(price),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
}
