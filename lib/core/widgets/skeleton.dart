import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class Skeleton extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? radius;

  const Skeleton({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark.withOpacity(0.6)
            : AppColors.cardLight.withOpacity(0.6),
        borderRadius: radius ?? BorderRadius.circular(12),
      ),
    );
  }
}
