import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class DashboardEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const DashboardEmptyState({
    super.key,
    this.title = 'Nothing here yet',
    this.subtitle = 'Start by creating something new',
    this.icon = Icons.inbox,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Icon(
              icon,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}