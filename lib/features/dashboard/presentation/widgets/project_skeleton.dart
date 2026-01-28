import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProjectListSkeleton extends StatelessWidget {
  const ProjectListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardDark.withOpacity(0.6)
              : AppColors.cardLight.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
