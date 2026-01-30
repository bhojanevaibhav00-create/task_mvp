import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onActionTap;
  final String actionLabel;

  const SectionHeader({
    super.key,
    required this.title,
    this.onActionTap,
    this.actionLabel = "See All",
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Standardized padding for dashboard consistency
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Section Title with Premium Typography
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827), // Slate-900 for high contrast
              letterSpacing: -0.5,
            ),
          ),
          
          // Optional Action Button (e.g., "See All")
          if (onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}