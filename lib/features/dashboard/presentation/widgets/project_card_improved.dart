import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/enums.dart';

class ProjectCardImproved extends StatelessWidget {
  final Project project;
  final VoidCallback? onOpenBoard;

  const ProjectCardImproved({
    super.key,
    required this.project,
    this.onOpenBoard,
  });

  @override
  Widget build(BuildContext context) {
    final totalTasks = project.tasks.length;
    final completedTasks =
        project.tasks.where((t) => t.status == TaskStatus.done).length;
    final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      elevation: AppColors.cardElevation,
      child: InkWell(
        onTap: onOpenBoard,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(project.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.progressBackground,
                color: AppColors.progressForeground,
                minHeight: 6,
              ),
              const SizedBox(height: 4),
              Text("$completedTasks/$totalTasks tasks completed",
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
