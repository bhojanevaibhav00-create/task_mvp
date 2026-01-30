import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Using the Drift database model for project data
import '../../../../data/database/database.dart' as db;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/task_providers.dart';

class ProjectCardImproved extends ConsumerWidget {
  final db.Project project;
  final VoidCallback? onOpenBoard;

  const ProjectCardImproved({
    super.key,
    required this.project,
    this.onOpenBoard,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching all tasks to calculate real-time progress for this project
    final tasksAsync = ref.watch(filteredTasksProvider);

    return tasksAsync.when(
      data: (allTasks) {
        // Filtering tasks belonging to this specific project
        final projectTasks = allTasks.where((t) => t.projectId == project.id).toList();
        final totalTasks = projectTasks.length;
        
        // Calculating progress based on 'done' status from DB
        final completedTasks = projectTasks.where((t) => t.status == 'done').length;
        final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

        return GestureDetector(
          onTap: onOpenBoard,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Premium Progress Indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$completedTasks/$totalTasks tasks completed",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      // Loading state for the card
      loading: () => const Center(child: CircularProgressIndicator()),
      // Error state handling
      error: (err, _) => Center(child: Text("Error: $err")),
    );
  }
}