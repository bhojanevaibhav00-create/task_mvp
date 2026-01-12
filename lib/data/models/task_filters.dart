import 'package:task_mvp/data/database/database.dart';

/// Helper class to filter and sort tasks in memory.
class TaskFilters {
  static List<Task> apply(
    List<Task> tasks, {
    String? status,
    int? priority,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    int? tagId,
    int? projectId,
    String? sortBy,
  }) {
    var filteredTasks = tasks.where((task) {
      // Status Filter
      if (status != null && task.status != status) {
        return false;
      }

      // Priority Filter
      if (priority != null && task.priority != priority) {
        return false;
      }

      // Tag Filter
      if (tagId != null && task.tagId != tagId) {
        return false;
      }

      // Project Filter
      if (projectId != null && task.projectId != projectId) {
        return false;
      }

      // Search Query (Title or Description)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesTitle = task.title.toLowerCase().contains(query);
        final matchesDesc =
            task.description?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesDesc) {
          return false;
        }
      }

      // Date Range Filter
      if (fromDate != null && toDate != null) {
        if (task.dueDate == null) return false;
        if (task.dueDate!.isBefore(fromDate) || task.dueDate!.isAfter(toDate)) {
          return false;
        }
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
            final pA = a.priority ?? 0;
            final pB = b.priority ?? 0;
            return pB.compareTo(pA);
          case 'updated_at_desc':
            final uA = a.updatedAt ?? DateTime(0);
            final uB = b.updatedAt ?? DateTime(0);
            return uB.compareTo(uA);
          default:
            return 0;
        }
      });
    }

    return filteredTasks;
  }
}
