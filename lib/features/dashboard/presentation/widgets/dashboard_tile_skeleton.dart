import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class DashboardTileSkeleton extends StatelessWidget {
  const DashboardTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 56,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardDark.withOpacity(0.6)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 140,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        );
      }),
    );
  }
}