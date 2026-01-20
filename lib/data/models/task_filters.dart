import '../models/task_model.dart';
import '../models/enums.dart';
import '../models/tag_model.dart';

class TaskFilters {
  /// Apply filters to a list of tasks
  static List<Task> apply(
      List<Task> tasks, {
        TaskStatus? status,
        Priority? priority,
        String? searchQuery,
        bool? isOverdue,
        bool? isToday,
        bool? isThisWeek,
        Set<Tag>? tags,
      }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    return tasks.where((task) {
      // Status filter
      if (status != null && task.status != status) return false;

      // Priority filter
      if (priority != null && task.priority != priority) return false;

      // Tag filter
      if (tags != null && tags.isNotEmpty) {
        final taskTags = task.tags ?? [];
        if (!taskTags.any((t) => tags.contains(t))) return false;
      }

      // Search filter (title or description) with null safety
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesTitle = (task.title ?? "").toLowerCase().contains(query);
        final matchesDesc = (task.description ?? "").toLowerCase().contains(query);
        if (!matchesTitle && !matchesDesc) return false;
      }

      // Date filters
      if (task.dueDate != null) {
        final taskDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );

        if (isOverdue == true && !taskDate.isBefore(today)) return false;
        if (isToday == true && taskDate != today) return false;
        if (isThisWeek == true && (taskDate.isBefore(today) || taskDate.isAfter(nextWeek))) {
          return false;
        }
      } else {
        // If no due date, cannot match date filters
        if (isOverdue == true || isToday == true || isThisWeek == true) return false;
      }

      return true;
    }).toList();
  }
}
