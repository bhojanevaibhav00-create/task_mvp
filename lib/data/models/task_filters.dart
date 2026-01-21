import 'package:task_mvp/data/database/database.dart';

/// Helper class to filter and sort tasks in memory.
class TaskFilters {
  /// Apply filters to a list of tasks
  static List<Task> apply(
    List<Task> tasks, {
    String? status,
    int? priority,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    bool? hasDueDate,
    int? tagId,
    int? projectId,
    String? sortBy,
  }) {
    var filteredTasks = tasks.where((task) {
      // Status Filter
      if (status != null && task.status != status) return false;

      // Priority Filter
      if (priority != null && task.priority != priority) return false;

      // Tag Filter
      if (tagId != null && task.tagId != tagId) return false;

      // Project Filter
      if (projectId != null && task.projectId != projectId) return false;

      // Search Filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final titleMatch = task.title.toLowerCase().contains(q);
        final descMatch =
            task.description?.toLowerCase().contains(q) ?? false;
        if (!titleMatch && !descMatch) return false;
      }

      // Due date existence
      if (hasDueDate != null) {
        if (hasDueDate && task.dueDate == null) return false;
        if (!hasDueDate && task.dueDate != null) return false;
      }

      // Date range filter
      if (fromDate != null || toDate != null) {
        if (task.dueDate == null) return false;
        if (fromDate != null && task.dueDate!.isBefore(fromDate)) return false;
        if (toDate != null && task.dueDate!.isAfter(toDate)) return false;
      }

      return true;
    }).toList();

    // Sorting
    if (sortBy != null) {
      filteredTasks.sort((a, b) {
        switch (sortBy) {
          case 'due_date_asc':
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);

          case 'priority_desc':
            return (b.priority ?? 0).compareTo(a.priority ?? 0);

          case 'updated_at_desc':
            final aDate = a.updatedAt ?? DateTime(0);
            final bDate = b.updatedAt ?? DateTime(0);
            return bDate.compareTo(aDate);

          default:
            return 0;
        }
      });
    }

    return filteredTasks;
  }
}
