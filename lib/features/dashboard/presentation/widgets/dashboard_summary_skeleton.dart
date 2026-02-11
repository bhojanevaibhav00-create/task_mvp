import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class DashboardSummarySkeleton extends StatelessWidget {
  const DashboardSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: const [
        Expanded(child: _SummaryCardSkeleton()),
        SizedBox(width: 12),
        Expanded(child: _SummaryCardSkeleton()),
        SizedBox(width: 12),
        Expanded(child: _SummaryCardSkeleton()),
      ],
    );
  }
}

class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark.withOpacity(0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(width: 30),
          const SizedBox(height: 12),
          _line(width: 60, height: 20),
          const SizedBox(height: 8),
          _line(width: 40),
        ],
      ),
    );
  }

  Widget _line({double width = 40, double height = 10}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}