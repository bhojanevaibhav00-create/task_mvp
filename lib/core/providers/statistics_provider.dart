import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_mvp/core/providers/task_providers.dart';


class ProjectStats {
  final int total;
  final int completed;
  final int pending;
  final double completionRate;

  ProjectStats({
    required this.total, 
    required this.completed, 
    required this.pending, 
    required this.completionRate
  });
}

final projectStatsProvider = Provider.family<ProjectStats, int>((ref, projectId) {
  // 1. We watch 'projectTasksProvider' which you defined in task_provider.dart
  final tasksAsync = ref.watch(projectTasksProvider(projectId));

  return tasksAsync.maybeWhen(
    data: (tasksWithAssignee) {
      // Since projectTasksProvider returns List<TaskWithAssignee>, 
      // we access the actual task object using .task
      final total = tasksWithAssignee.length;
      
      // 2. Filter based on your TaskStatus enum logic
      // In your addTask method, you use TaskStatus.todo.name
      // So 'completed' tasks are usually 'done'
      final completedCount = tasksWithAssignee.where((t) => 
        t.task.status == 'done' // Change to 'Done' if your DB uses Capitalized strings
      ).length; 
      
      final pendingCount = total - completedCount;
      final rate = total > 0 ? (completedCount / total) : 0.0;

      return ProjectStats(
        total: total,
        completed: completedCount,
        pending: pendingCount,
        completionRate: rate,
      );
    },
    // Show 0 while loading or on error to prevent UI crashes
    orElse: () => ProjectStats(total: 0, completed: 0, pending: 0, completionRate: 0.0),
  );
});