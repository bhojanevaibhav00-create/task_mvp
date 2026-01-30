import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SummaryCardSkeleton extends StatelessWidget {
  const SummaryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardDark.withOpacity(0.6)
              : AppColors.cardLight.withOpacity(0.6),
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
        ),
      ),
    );
  }
}
