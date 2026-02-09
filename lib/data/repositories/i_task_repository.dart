import '../database/database.dart';

abstract class ITaskRepository {
  Future<int> createTask(TasksCompanion task);

  Future<List<Task>> getAllTasks();

  Stream<List<Task>> watchTasks({
    List<String>? statuses,
    int? priority,
    DateTime? fromDate,
    DateTime? toDate,
    bool? hasDueDate,
    int? tagId,
    int? projectId,
    String sortBy = 'updated_at_desc',
  });

  Future<Task?> getTaskById(int id);

  Future<bool> updateTask(Task task);

  Future<int> deleteTask(int id);

  Future<int> deleteAllTasks();

  Future<void> seedDatabase();

  /// IMPORTANT
  Future<List<ActivityLog>> getRecentActivity();

  Future<List<Task>> fetchUpcomingReminders(DateTime from, DateTime to);

  Future<int> getDatabaseVersion();
}