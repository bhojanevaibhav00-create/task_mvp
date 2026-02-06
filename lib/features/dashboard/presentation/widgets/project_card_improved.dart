import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Using the Drift database model for project data
import '../../../../data/database/database.dart' as db;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/task_providers.dart';
import '../../../../data/repositories/task_repository.dart'; // ✅ Added for TaskWithAssignee type

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
    // 🚀 FIXED: Watching the provider which now returns TaskWithAssignee
    final tasksAsync = ref.watch(filteredTasksProvider);

    return tasksAsync.when(
      data: (List<TaskWithAssignee> taskWrappers) {
        // ✅ 1. Filter and Unwrap: Extracting db.Task from the wrappers for this project
        final projectTasks = taskWrappers
            .where((w) => w.task.projectId == project.id)
            .map((w) => w.task)
            .toList();
            
        final totalTasks = projectTasks.length;
        
        // ✅ 2. Calculate Progress: Standardizing status check to lowercase
        final completedTasks = projectTasks.where((t) => 
          t.status?.toLowerCase() == 'done'
        ).length;
        
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
      // Loading state for the card (matches Dashboard style)
      loading: () => Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      // Error state handling
      error: (err, _) => Container(
        padding: const EdgeInsets.all(16),
        child: Text("Error: $err", style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}