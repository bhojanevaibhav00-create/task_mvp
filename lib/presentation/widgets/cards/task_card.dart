import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String status;
  final String priority;
  final String dueDate;

  const TaskCard({
    super.key,
    required this.title,
    required this.status,
    required this.priority,
    required this.dueDate,
  });

  Color _statusColor() {
    switch (status) {
      case "Done":
        return Colors.green;
      case "In Progress":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: 8),

          Row(
            children: [
              _Chip(label: priority, color: AppColors.primary),
              const SizedBox(width: 8),
              _Chip(label: status, color: _statusColor()),
            ],
          ),

          const SizedBox(height: 8),
          Text("Due: $dueDate", style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
