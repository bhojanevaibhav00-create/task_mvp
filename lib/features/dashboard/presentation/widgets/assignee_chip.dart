import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AssigneeChip extends StatelessWidget {
  final String? name;
  final VoidCallback? onTap;
  final bool showClear;

  const AssigneeChip({
    super.key,
    required this.name,
    this.onTap,
    this.showClear = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAssigned = name != null && name!.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isAssigned
              ? AppColors.primary.withOpacity(0.12)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAssigned
                ? AppColors.primary
                : Colors.grey.shade400,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: isAssigned
                  ? AppColors.primary
                  : Colors.grey,
              child: Text(
                isAssigned ? name![0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isAssigned ? name! : 'Unassigned',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isAssigned
                    ? AppColors.primary
                    : Colors.grey.shade700,
              ),
            ),
            if (showClear && isAssigned) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.close,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}