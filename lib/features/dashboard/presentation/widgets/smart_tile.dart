import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SmartTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? count; // Added count for backend integration
  final Color? color;
  final VoidCallback? onTap;

  const SmartTile({
    super.key,
    required this.icon,
    required this.label,
    this.count,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), // Premium rounded corners
          boxShadow: [
            BoxShadow(
              color: tileColor.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.03)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon with soft background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tileColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: tileColor),
            ),
            
            // Label and Count section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (count != null)
                  Text(
                    count!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}