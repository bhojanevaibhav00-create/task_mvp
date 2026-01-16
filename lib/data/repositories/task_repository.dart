import 'package:drift/drift.dart';
import 'package:task_mvp/data/database/database.dart';
import '../seed/seed_data.dart';
import 'i_task_repository.dart';

class TaskRepository implements ITaskRepository {
  final AppDatabase _db;

  TaskRepository(this._db);

  // Create
  Future<int> createTask(TasksCompanion task) async {
    final id = await _db.into(_db.tasks).insert(task);

    if (task.title.present) {
      await _logActivity(
        'created',
        'Task "${task.title.value}" created',
        taskId: id,
        projectId: task.projectId.value,
      );
    }

    return id;
  }

  // Read
  Future<List<Task>> getAllTasks() async {
    return await _db.select(_db.tasks).get();
  }

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

    // Filters
    if (statuses != null && statuses.isNotEmpty) {
      query.where((t) => t.status.isIn(statuses));
    }
    if (priority != null) {
      query.where((t) => t.priority.equals(priority));
    }

    // Date Filters
    if (hasDueDate != null) {
      query.where(
        (t) => hasDueDate ? t.dueDate.isNotNull() : t.dueDate.isNull(),
      );
    }

    // Apply range filters only if we aren't strictly looking for "No Date"
    if (hasDueDate != false) {
      if (fromDate != null && toDate != null) {
        query.where((t) => t.dueDate.isBetweenValues(fromDate, toDate));
      } else if (fromDate != null) {
        query.where((t) => t.dueDate.isBiggerOrEqualValue(fromDate));
      } else if (toDate != null) {
        query.where((t) => t.dueDate.isSmallerOrEqualValue(toDate));
      }
    }

    if (tagId != null) {
      query.where((t) => t.tagId.equals(tagId));
    }
    if (projectId != null) {
      query.where((t) => t.projectId.equals(projectId));
    }

    // Sorting
    List<OrderingTerm Function($TasksTable)> orderings = [];
    switch (sortBy) {
      case 'due_date_asc':
        orderings.add(
          (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.asc),
        );
        break;
      case 'priority_desc':
        orderings.add(
          (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
        );
        break;
      case 'updated_at_desc':
      default:
        orderings.add(
          (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        );
        break;
    }
    query.orderBy(orderings);

    return query.watch();
  }

  Future<Task?> getTaskById(int id) async {
    return await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Fetches upcoming reminders within a specific time range.
  /// Useful for a background scheduler to find tasks that need notification.
  Future<List<Task>> fetchUpcomingReminders(DateTime from, DateTime to) {
    return (_db.select(_db.tasks)
          ..where((t) => t.reminderEnabled.equals(true))
          ..where((t) => t.reminderAt.isBetweenValues(from, to))
          ..where((t) => t.status.isNotValue('done')))
        .get();
  }

  // Update
  Future<bool> updateTask(Task task) async {
    final oldTask = await getTaskById(task.id);
    if (oldTask == null) return false;

    final now = DateTime.now();

    // Determine completion status change
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

    if (result) {
      if (oldTask.status != task.status) {
        if (task.status == 'done') {
          await _logActivity(
            'completed',
            'Task "${task.title}" completed',
            taskId: task.id,
            projectId: task.projectId,
          );
        } else {
          await _logActivity(
            'status_changed',
            'Status changed from ${oldTask.status} to ${task.status}',
            taskId: task.id,
            projectId: task.projectId,
          );
        }
      }

      if (oldTask.projectId != task.projectId) {
        await _logActivity(
          'moved',
          'Moved to project ${task.projectId ?? "none"}',
          taskId: task.id,
          projectId: task.projectId,
        );
      }

      // Check for assignee change
      // Note: Ensure 'assigneeId' is added to Tasks table in database.dart
      if (oldTask.assigneeId != task.assigneeId) {
        await _logActivity(
          'assigned',
          task.assigneeId != null
              ? 'Assigned to user ${task.assigneeId}'
              : 'Unassigned',
          taskId: task.id,
          projectId: task.projectId,
        );
      }

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
    }
    return result;
  }

  // Delete
  Future<int> deleteTask(int id) async {
    return await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }

  // Delete All (For testing/seeding)
  Future<int> deleteAllTasks() async {
    return await _db.delete(_db.tasks).go();
  }

  // Seed Data
  Future<void> seedDatabase() async {
    await SeedData.generate(_db);
  }

  // Check DB Version
  Future<int> getDatabaseVersion() async {
    return await _db.getDatabaseVersion();
  }

  // Deprecated: Use watchTasks instead
  Stream<List<Task>> watchAllTasks() {
    return watchTasks();
  }

  // Activity Logs
  Future<List<ActivityLog>> getRecentActivity() async {
    return await (_db.select(_db.activityLogs)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(20))
        .get();
  }

  // Activity Logs per Project
  Future<List<ActivityLog>> getRecentActivityByProject(int projectId) async {
    return await (_db.select(_db.activityLogs)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(20))
        .get();
  }

  Future<void> _logActivity(
    String action,
    String description, {
    int? taskId,
    int? projectId,
  }) async {
    await _db
        .into(_db.activityLogs)
        .insert(
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

/*
How to use TaskRepository:

1. Initialize the database and repository:
   final db = AppDatabase();
   final taskRepo = TaskRepository(db);

2. Create a task:
   await taskRepo.createTask(
     TasksCompanion.insert(
       title: 'New Task',
       description: const Value('Task description'),
       status: const Value('todo'),
     ),
   );

3. Get all tasks:
   final tasks = await taskRepo.getAllTasks();

4. Watch tasks (for StreamBuilder):
   Stream<List<Task>> taskStream = taskRepo.watchTasks(status: ['todo'], sortBy: 'priority_desc');

5. Update a task:
   // Assuming you have a 'task' object from the DB
   final updatedTask = task.copyWith(title: 'Updated Task Title');
   await taskRepo.updateTask(updatedTask);

6. Delete a task:
   await taskRepo.deleteTask(taskId);
*/
