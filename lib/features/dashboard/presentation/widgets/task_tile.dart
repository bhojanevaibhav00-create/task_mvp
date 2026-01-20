import 'package:flutter/material.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/enums.dart';
import '../../../../core/constants/app_colors.dart';

class TaskTile extends StatelessWidget {
  final Task task;

  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.cardRadius)),
      elevation: AppColors.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (task.important)
                  const Icon(Icons.star, color: Colors.orange, size: 18),
                Expanded(
                  child: Text(task.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (task.dueDate != null)
                  Text(
                    "Due: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(width: 12),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: task.priority.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    task.priority.name.toUpperCase(),
                    style: TextStyle(
                        color: task.priority.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
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
