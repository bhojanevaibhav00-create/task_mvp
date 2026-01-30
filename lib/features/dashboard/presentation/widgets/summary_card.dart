import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final LinearGradient gradient;
  final IconData? icon;

  const SummaryCard({
    super.key,
    required this.title,
    required this.count,
    required this.gradient,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ VAISHNAVI: Theme-aware logic for Sprint 7 QA
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 115),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              // ✅ VAISHNAVI: Adaptive shadow color
              color: isDark ? Colors.black38 : gradient.colors.first.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ✅ MAIN: Background Decorative Icon for premium look
            if (icon != null)
              Positioned(
                right: -12,
                bottom: -12,
                child: Icon(
                  icon,
                  size: 70,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon Header (Vaishnavi style)
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),

                const SizedBox(height: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}