import 'package:flutter/material.dart';
import 'package:task_mvp/data/models/task_model.dart';
import 'package:task_mvp/core/constants/app_colors.dart';

class TaskTile extends StatelessWidget {
  final Task task;

  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.cardRadius)),
      elevation: AppColors.cardElevation,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(task.title),
        subtitle: task.dueDate != null ? Text("Due: ${task.dueDate}") : null,
        trailing: task.important ? const Icon(Icons.star, size: 16, color: Colors.amber) : null,
      ),
    );
  }
}
