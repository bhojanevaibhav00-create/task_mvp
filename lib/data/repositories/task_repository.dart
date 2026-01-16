import 'package:drift/drift.dart';
import 'package:task_mvp/data/database/database.dart';
import '../seed/seed_data.dart';
import 'i_task_repository.dart';
import 'package:task_mvp/data/repositories/notification_repository.dart';

class TaskRepository implements ITaskRepository {
  final AppDatabase _db;
  final NotificationRepository _notificationRepo;

  /// ✅ FIXED constructor (IMPORTANT)
  TaskRepository(this._db, this._notificationRepo);

  // ================= CREATE =================
  @override
  Future<int> createTask(TasksCompanion task) async {
    final id = await _db.into(_db.tasks).insert(task);

    // Activity log
    if (task.title.present) {
      await _logActivity(
        'created',
        'Task "${task.title.value}" created',
        taskId: id,
        projectId: task.projectId.value,
      );
    }

    // ✅ Notification
    await _notificationRepo.addNotification(
      NotificationsCompanion.insert(
        type: 'task',
        title: 'Task Created',
        message: 'Task "${task.title.value}" created',
        taskId: Value(id),
        projectId: Value(task.projectId.value),
      ),
    );

    return id;
  }

  // ================= READ =================
  @override
  Future<List<Task>> getAllTasks() async {
    return _db.select(_db.tasks).get();
  }

  @override
  Stream<List<Task>> watchTasks({
    List<String>? statuses,
    int? priority,
    DateTime? fromDate,
    DateTime? toDate,
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
    if (fromDate != null && toDate != null) {
      query.where((t) => t.dueDate.isBetweenValues(fromDate, toDate));
    }
    if (tagId != null) {
      query.where((t) => t.tagId.equals(tagId));
    }
    if (projectId != null) {
      query.where((t) => t.projectId.equals(projectId));
    }

    // Sorting
    query.orderBy([
      switch (sortBy) {
        'due_date_asc' =>
          (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.asc),
        'priority_desc' =>
          (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
        _ =>
          (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      }
    ]);

    return query.watch();
  }

  @override
  Future<Task?> getTaskById(int id) {
    return (_db.select(_db.tasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ================= REMINDERS =================
  @override
  Future<List<Task>> fetchUpcomingReminders(DateTime from, DateTime to) {
    return (_db.select(_db.tasks)
          ..where((t) => t.reminderEnabled.equals(true))
          ..where((t) => t.reminderAt.isBetweenValues(from, to))
          ..where((t) => t.status.isNotValue('done')))
        .get();
  }

  // ================= UPDATE =================
  @override
  Future<bool> updateTask(Task task) async {
    final oldTask = await getTaskById(task.id);
    if (oldTask == null) return false;

    final now = DateTime.now();

    final isCompleted = task.status == 'done';
    final wasCompleted = oldTask.status == 'done';

    DateTime? completedAt = oldTask.completedAt;
    if (isCompleted && !wasCompleted) {
      completedAt = now;
    } else if (!isCompleted && wasCompleted) {
      completedAt = null;
    }

    final updated = task.copyWith(
      updatedAt: Value(now),
      completedAt: Value(completedAt),
    );

    final result = await _db.update(_db.tasks).replace(updated);

    if (!result) return false;

    // ---------- STATUS CHANGE ----------
    if (oldTask.status != task.status) {
      if (task.status == 'done') {
        await _logActivity(
          'completed',
          'Task "${task.title}" completed',
          taskId: task.id,
          projectId: task.projectId,
        );

        await _notificationRepo.addNotification(
          NotificationsCompanion.insert(
            type: 'task',
            title: 'Task Completed',
            message: 'Task "${task.title}" completed',
            taskId: Value(task.id),
            projectId: Value(task.projectId),
          ),
        );
      } else {
        await _logActivity(
          'status_changed',
          'Status changed from ${oldTask.status} to ${task.status}',
          taskId: task.id,
          projectId: task.projectId,
        );

        await _notificationRepo.addNotification(
          NotificationsCompanion.insert(
            type: 'task',
            title: 'Task Updated',
            message:
                'Status changed from ${oldTask.status} to ${task.status}',
            taskId: Value(task.id),
            projectId: Value(task.projectId),
          ),
        );
      }
    }

    // ---------- FIELD CHANGES ----------
    final changes = <String>[];
    if (oldTask.title != task.title) changes.add('title');
    if (oldTask.description != task.description) changes.add('description');
    if (oldTask.dueDate != task.dueDate) changes.add('due date');
    if (oldTask.priority != task.priority) changes.add('priority');

    if (changes.isNotEmpty) {
      await _logActivity(
        'edited',
        'Updated ${changes.join(', ')}',
        taskId: task.id,
        projectId: task.projectId,
      );
    }

    return true;
  }

  // ================= DELETE =================
  @override
  Future<int> deleteTask(int id) {
    return (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<int> deleteAllTasks() => _db.delete(_db.tasks).go();

  // ================= SEED =================
  @override
  Future<void> seedDatabase() => SeedData.generate(_db);

  @override
  Future<int> getDatabaseVersion() => _db.getDatabaseVersion();

  @override
  Stream<List<Task>> watchAllTasks() => watchTasks();

  // ================= ACTIVITY =================
  @override
  Future<List<ActivityLog>> getRecentActivity() {
    return (_db.select(_db.activityLogs)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(20))
        .get();
  }

  @override
  Future<List<ActivityLog>> getRecentActivityByProject(int projectId) {
    return (_db.select(_db.activityLogs)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(20))
        .get();
  }

  // ================= PRIVATE =================
  Future<void> _logActivity(
    String action,
    String description, {
    int? taskId,
    int? projectId,
  }) async {
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
