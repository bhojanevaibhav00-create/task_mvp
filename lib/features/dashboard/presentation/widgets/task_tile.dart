import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/task_model.dart';
import 'package:task_mvp/data/models/enums.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  const TaskTile({super.key, required this.task});

  Color getPriorityColor() {
    switch (task.priority) {
      case Priority.high:
        return AppColors.highPriority;
      case Priority.medium:
        return AppColors.mediumPriority;
      case Priority.low:
        return AppColors.lowPriority;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(task.title),
        subtitle: Row(
          children: [
            if (task.dueDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text("${task.dueDate!.day}/${task.dueDate!.month}"),
              ),
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: getPriorityColor(),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
