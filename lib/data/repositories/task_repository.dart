import 'package:drift/drift.dart';
import 'package:task_mvp/data/database/database.dart';
import 'package:task_mvp/data/repositories/notification_repository.dart';
import '../seed/seed_data.dart';
import 'i_task_repository.dart';
import 'package:task_mvp/core/services/reminder_service.dart';

class TaskRepository implements ITaskRepository {
  final AppDatabase _db;
  final NotificationRepository _notificationRepo;
  final ReminderService _reminderService;

  TaskRepository(this._db, this._notificationRepo, this._reminderService);

  @override
  Future<int> createTask(TasksCompanion task) async {
    final id = await _db.into(_db.tasks).insert(task);
    final createdTask = await getTaskById(id);

    if (createdTask != null) {
      await _reminderService.schedule(createdTask);
    }

    if (task.title.present) {
      await _logActivity(
        'created',
        'Task "${task.title.value}" created',
        taskId: id,
        projectId: task.projectId.value,
      );

      await _notificationRepo.addNotification(
        NotificationsCompanion.insert(
          type: 'task',
          title: 'Task Created',
          message: 'Task "${task.title.value}" created',
          taskId: Value(id),
          projectId: Value(task.projectId.value),
        ),
      );
    }
    return id;
  }

  @override
  Future<List<Task>> getAllTasks() => _db.select(_db.tasks).get();

  @override
  Stream<List<Task>> watchTasks({
    List<String>? statuses,
    int? priority,
    DateTime? fromDate,
    DateTime? toDate,
    bool? hasDueDate,
    int? tagId,
    int? projectId,
    String sortBy = 'updated_at_desc',
  }) {
    final query = _db.select(_db.tasks);

    if (statuses != null && statuses.isNotEmpty) {
      query.where((t) => t.status.isIn(statuses));
    }
    if (priority != null) {
      query.where((t) => t.priority.equals(priority));
    }
    if (hasDueDate != null) {
      query.where((t) => hasDueDate ? t.dueDate.isNotNull() : t.dueDate.isNull());
    }
    if (fromDate != null && toDate != null) {
      query.where((t) => t.dueDate.isBetweenValues(fromDate, toDate));
    }
    if (tagId != null) query.where((t) => t.tagId.equals(tagId));
    if (projectId != null) query.where((t) => t.projectId.equals(projectId));

    query.orderBy([
      switch (sortBy) {
        'priority_desc' => (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
        'due_date_asc' => (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.asc),
        _ => (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      },
    ]);

    return query.watch();
  }

  @override
  Future<Task?> getTaskById(int id) {
    return (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<List<Task>> fetchUpcomingReminders(DateTime from, DateTime to) {
    return (_db.select(_db.tasks)
          ..where((t) => t.reminderEnabled.equals(true))
          ..where((t) => t.reminderAt.isBetweenValues(from, to))
          ..where((t) => t.status.isNotValue('done')))
        .get();
  }

  @override
  Future<bool> updateTask(Task task) async {
    final old = await getTaskById(task.id);
    if (old == null) return false;

    if (task.status == 'done') {
      await _reminderService.cancel(task.id);
    }
    if (task.reminderEnabled == true) {
      await _reminderService.schedule(task);
    }

    final now = DateTime.now();
    final updated = task.copyWith(
      updatedAt: Value(now),
      completedAt: Value(task.status == 'done' ? now : null),
    );

    final ok = await _db.update(_db.tasks).replace(updated);

    if (ok) {
      await _logActivity('edited', 'Task updated', taskId: task.id, projectId: task.projectId);
      await _notificationRepo.addNotification(
        NotificationsCompanion.insert(
          type: 'task',
          title: 'Task Updated',
          message: 'Task "${task.title}" updated',
          taskId: Value(task.id),
          projectId: Value(task.projectId),
        ),
      );
    }
    return ok;
  }

  @override
  Future<int> deleteTask(int id) async {
    await _reminderService.cancel(id);
    return (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<int> deleteAllTasks() async {
    return _db.delete(_db.tasks).go();
  }

  @override
  Future<void> seedDatabase() => SeedData(_db).seed();

  // 🚀 FIXED METHOD
  @override
  Future<int> getDatabaseVersion() => _db.getDatabaseVersion();

  @override
  Future<List<ActivityLog>> getRecentActivity() {
    return (_db.select(_db.activityLogs)
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])
          ..limit(20))
        .get();
  }

  Future<void> _logActivity(String action, String description, {int? taskId, int? projectId}) async {
    await _db.into(_db.activityLogs).insert(
          ActivityLogsCompanion.insert(
            action: action,
            description: Value(description),
            taskId: Value(taskId),
            projectId: Value(projectId),
            timestamp: Value(DateTime.now()),
          ),
        );
  }
}