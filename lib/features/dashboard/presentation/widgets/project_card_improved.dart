import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/models/task_model.dart';
import '../board_screen.dart';
import 'package:task_mvp/data/models/enums.dart';

class ProjectCardImproved extends StatelessWidget {
  final Project project;
  final VoidCallback onOpenBoard;

  const ProjectCardImproved({
    super.key,
    required this.project,
    required this.onOpenBoard,
  });

  double getProgress() {
    if (project.tasks.isEmpty) return 0;
    final completed = project.tasks.where((t) => t.status == TaskStatus.done).length;
    return completed / project.tasks.length;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onOpenBoard,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(project.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: getProgress(),
                backgroundColor: AppColors.progressBackground,
                color: AppColors.progressForeground,
              ),
              const SizedBox(height: 8),
              Text(
                "${project.tasks.length} tasks • ${project.tasks.where((t) => t.status == TaskStatus.done).length} completed",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
