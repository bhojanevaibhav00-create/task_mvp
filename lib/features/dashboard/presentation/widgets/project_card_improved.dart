import 'package:flutter/material.dart';
import 'package:task_mvp/data/models/project_model.dart';
import 'package:task_mvp/data/models/task_model.dart';
import 'package:task_mvp/data/models/enums.dart'; // ✅ REQUIRED
import 'package:task_mvp/core/constants/app_colors.dart';

class ProjectCardImproved extends StatelessWidget {
  final Project project;
  final VoidCallback onOpenBoard;

  const ProjectCardImproved({
    super.key,
    required this.project,
    required this.onOpenBoard,
  });

  @override
  Widget build(BuildContext context) {
    final totalTasks = project.tasks.length;
    final completedTasks =
        project.tasks.where((t) => t.status == TaskStatus.done).length;

    final progress =
    totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    return Card(
      elevation: AppColors.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        onTap: onOpenBoard,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Project name
              Text(
                project.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              /// Progress bar
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
              ),

              const SizedBox(height: 6),

              /// Progress text
              Text(
                "$completedTasks / $totalTasks tasks completed",
                style: Theme.of(context)
                    .textTheme
                    .labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
