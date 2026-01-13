import '../database/database.dart';

/// Contract for the Task Repository to ensure UI consistency.
///
/// This interface defines all available data operations for the UI layer.
abstract class ITaskRepository {
  /// Creates a new task and logs the 'created' activity.
  /// Returns the auto-generated ID of the new task.
  Future<int> createTask(TasksCompanion task);

  /// Fetches all tasks from the database without filtering.
  Future<List<Task>> getAllTasks();

  /// Returns a stream of tasks that updates automatically when the database changes.
  ///
  /// Supports advanced filtering and sorting:
  /// * [statuses]: List of status strings (e.g., 'todo', 'done').
  /// * [priority]: Filter by priority level (1=Low, 2=Medium, 3=High).
  /// * [fromDate] / [toDate]: Filter tasks due within this date range.
  /// * [tagId]: Filter by specific tag ID.
  /// * [projectId]: Filter by specific project ID.
  /// * [sortBy]: Sort key ('due_date_asc', 'priority_desc', 'updated_at_desc').
  Stream<List<Task>> watchTasks({
    List<String>? statuses,
    int? priority,
    DateTime? fromDate,
    DateTime? toDate,
    int? tagId,
    int? projectId,
    String sortBy = 'updated_at_desc',
  });

  /// Fetches a single task by its unique [id].
  Future<Task?> getTaskById(int id);

  /// Updates an existing task.
  ///
  /// Automatically handles:
  /// * Updating `updatedAt` timestamp.
  /// * Setting/clearing `completedAt` based on status.
  /// * Logging activities (status change, edit, move, completion).
  Future<bool> updateTask(Task task);

  /// Deletes a task by its [id].
  Future<int> deleteTask(int id);

  /// Deletes all tasks from the database.
  Future<int> deleteAllTasks();

  /// Populates the database with sample projects, tags, and tasks.
  Future<void> seedDatabase();

  /// Fetches the most recent activity logs (limit 20).
  Future<List<ActivityLog>> getRecentActivity();
}
