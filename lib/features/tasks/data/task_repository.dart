import '../domain/task_entity.dart';
import 'dart:math';

class TaskRepository {
  static final List<TaskEntity> _tasks = [];

  static List<TaskEntity> getAllTasks() => List.unmodifiable(_tasks);

  static void addTask(String title, {DateTime? dueDate}) {
    _tasks.add(
      TaskEntity(
        id: Random().nextInt(999999).toString(),
        title: title,
        dueDate: dueDate,
      ),
    );
  }

  // ✅ REQUIRED METHODS
  static List<TaskEntity> todayTasks() {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return _isSameDay(t.dueDate!, now) &&
          t.status != TaskStatus.done;
    }).toList();
  }

  static List<TaskEntity> overdueTasks() {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.isBefore(now) &&
          t.status != TaskStatus.done;
    }).toList();
  }

  static List<TaskEntity> upcomingTasks() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.isAfter(now) &&
          t.dueDate!.isBefore(nextWeek);
    }).toList();
  }

  static List<TaskEntity> recentTasks({int limit = 5}) {
    final sorted = [..._tasks];
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }
}
