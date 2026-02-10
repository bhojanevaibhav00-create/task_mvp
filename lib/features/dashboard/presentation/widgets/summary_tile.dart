import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// ✅ LOADING STATE: Vaishnavi's SummarySkeleton
/// Essential for the Sprint 7 QA checklist to handle loading states smoothly.
class SummarySkeleton extends StatelessWidget {
  const SummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(width: 28, height: 28),
            const SizedBox(height: 16),
            _bar(width: 60, height: 20),
            const SizedBox(height: 8),
            _bar(width: 80, height: 12),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.chipBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// ✅ DATA STATE: Main branch SummaryTile
/// Reusable premium card for displaying workspace overview stats.
class SummaryTile extends StatelessWidget {
  final String title;
  final int count;
  final Gradient gradient;
  final IconData? icon;

  const SummaryTile({
    super.key,
    required this.title,
    required this.count,
    required this.gradient,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // VAISHNAVI: Adaptive shadow for Dark Mode compatibility
            color: isDark
                ? Colors.black45
                : (gradient is LinearGradient
                      ? (gradient as LinearGradient).colors.first.withOpacity(
                          0.3,
                        )
                      : Colors.black12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (icon != null)
            Positioned(
              right: -12,
              bottom: -12,
              child: Icon(
                icon,
                size: 64,
                color: Colors.white.withOpacity(0.15),
              ),
            ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
