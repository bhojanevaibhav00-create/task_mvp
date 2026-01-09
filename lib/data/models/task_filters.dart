import 'task_model.dart';
import 'enums.dart';

class TaskFilters {
  /// Filters tasks based on multiple criteria.
  static List<Task> apply(
    List<Task> tasks, {
    TaskStatus? status,
    Priority? priority,
    String? searchQuery,
    bool? isOverdue,
    bool? isToday,
    bool? isThisWeek,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    return tasks.where((task) {
      // Status Filter
      if (status != null && task.status != status) {
        return false;
      }

      // Priority Filter
      if (priority != null && task.priority != priority) {
        return false;
      }

      // Search Query (Title or Description)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesTitle = task.title.toLowerCase().contains(query);
        final matchesDesc = task.description.toLowerCase().contains(query);
        if (!matchesTitle && !matchesDesc) {
          return false;
        }
      }

      // Date Filters
      if (task.dueDate != null) {
        final taskDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );

        if (isOverdue == true && !taskDate.isBefore(today)) return false;
        // Note: Logic above assumes 'overdue' means strictly before today.

        if (isToday == true && taskDate != today) return false;

        if (isThisWeek == true) {
          if (taskDate.isBefore(today) || taskDate.isAfter(nextWeek)) {
            return false;
          }
        }
      } else {
        // If no due date, it cannot match any date-based filter
        if (isOverdue == true || isToday == true || isThisWeek == true) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
