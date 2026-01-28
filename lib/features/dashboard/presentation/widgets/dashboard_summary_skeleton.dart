import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class DashboardSummarySkeleton extends StatelessWidget {
  const DashboardSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.chipBackground,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
