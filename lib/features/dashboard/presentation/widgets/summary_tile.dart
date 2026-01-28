import 'package:flutter/material.dart';

class SummaryTile extends StatelessWidget {
  final String title;
  final int count;
  final Gradient gradient;
  final IconData? icon; // Added for visual context

  const SummaryTile({
    super.key,
    required this.title,
    required this.count,
    required this.gradient,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // 🚀 Fixed: Removed direct Expanded to make the widget more reusable
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24), // Premium rounded corners
        boxShadow: [
          BoxShadow(
            // Dynamic shadow based on gradient color
            color: (gradient as LinearGradient).colors.first.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Decorative Icon
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