import 'package:flutter/material.dart';
// Use the drift database model for backend synchronization
import '../../../../data/database/database.dart' as db;
import '../../../../core/constants/app_colors.dart';

class TaskTile extends StatelessWidget {
  // Database Task Model
  final db.Task task;

  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row for Status or Priority Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriorityBadge(task.priority), // This handles the int value
              const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          
          // Task Title
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          
          // Task Description (Optional)
          if (task.description != null && task.description!.isNotEmpty)
            Text(
              task.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.4),
            ),
          
          const SizedBox(height: 16),
          
          // Footer with Member Avatar and Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Displaying initials if assignee exists
              if (task.assigneeId != null)
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Text(
                    "M", // Placeholder for Member Initial
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                )
              else
                const Icon(Icons.account_circle_outlined, size: 20, color: Colors.grey),
                
              const Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                  SizedBox(width: 4),
                  Text("Jan 28", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Helper method to fix 'task.priority' error
  Widget _buildPriorityBadge(int? priority) {
    Color color;
    String label;

    // Mapping integer values from DB to UI labels
    switch (priority) {
      case 3:
        color = const Color(0xFFEF4444); // High - Red
        label = "High";
        break;
      case 2:
        color = const Color(0xFFF59E0B); // Medium - Amber
        label = "Medium";
        break;
      case 1:
      default:
        color = const Color(0xFF10B981); // Low - Emerald
        label = "Low";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}