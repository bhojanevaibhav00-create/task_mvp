import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import 'package:task_mvp/data/database/database.dart';
import 'package:task_mvp/data/repositories/task_repository.dart';
import 'package:task_mvp/data/repositories/notification_repository.dart';
import 'package:task_mvp/data/repositories/collaboration_repository.dart';
import 'package:task_mvp/core/services/reminder_service.dart';
import 'package:task_mvp/data/models/enums.dart';
import 'package:task_mvp/core/providers/database_provider.dart';

/// ======================================================
/// DATABASE PROVIDER
/// ======================================================


/// ======================================================
/// REPOSITORY PROVIDERS
/// ======================================================
final notificationRepositoryProvider =
Provider<NotificationRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NotificationRepository(db);
});

final reminderServiceProvider = Provider<ReminderService>((ref) {
  final db = ref.watch(databaseProvider);
  return ReminderService(db);
});

final collaborationRepositoryProvider =
Provider<CollaborationRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  return CollaborationRepository(db, notificationRepo);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  final reminderService = ref.watch(reminderServiceProvider);
  return TaskRepository(db, notificationRepo, reminderService);
});

/// ======================================================
/// TASKS NOTIFIER
/// ======================================================
class TasksNotifier extends StateNotifier<List<Task>> {
  final TaskRepository _repository;
  final Ref _ref;

  TasksNotifier(this._repository, this._ref) : super([]) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      state = await _repository.getAllTasks();
    } catch (_) {
      state = [];
    }
  }

  /// ---------------- CREATE TASK ----------------
  Future<void> addTask(
      String title,
      String description, {
        int priority = 1,
        DateTime? dueDate,
        int? assigneeId,
        int? projectId,
      }) async {
    final task = TasksCompanion.insert(
      title: title,
      description:
      drift.Value(description.isEmpty ? null : description),
      priority: drift.Value(priority),
      status: drift.Value(TaskStatus.todo.name),
      dueDate: drift.Value(dueDate),
      assigneeId: drift.Value(assigneeId),
      projectId: drift.Value(projectId),
      createdAt: drift.Value(DateTime.now()),
    );

    final taskId = await _repository.createTask(task);

    if (assigneeId != null) {
      await _logAssignment(taskId, title, projectId);
    }

    await loadTasks();
  }

  /// ---------------- UPDATE TASK ----------------
  Future<void> updateTask(Task task) async {
    final oldTask =
    state.firstWhere((t) => t.id == task.id, orElse: () => task);

    await _repository.updateTask(task);

    if (task.assigneeId != null &&
        task.assigneeId != oldTask.assigneeId) {
      await _logAssignment(
        task.id,
        task.title,
        task.projectId,
      );
    }

    await loadTasks();
  }

  /// ---------------- DELETE TASK ----------------
  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
    await loadTasks();
  }

  /// ======================================================
  /// ACTIVITY + NOTIFICATION (DIRECT DB — SAFE)
  /// ======================================================
  Future<void> _logAssignment(
      int taskId,
      String title,
      int? projectId,
      ) async {
    final db = _ref.read(databaseProvider);

    // Activity Log
    await db.into(db.activityLogs).insert(
      ActivityLogsCompanion.insert(
        action: 'Task Assigned',
        description:
        drift.Value('Assigned task: $title'),
        taskId: drift.Value(taskId),
        projectId: drift.Value(projectId),
        timestamp: drift.Value(DateTime.now()),
      ),
    );

    // Notification
    await db.into(db.notifications).insert(
      NotificationsCompanion.insert(
        type: 'assignment',
        title: 'Task Assigned',
        message: 'You were assigned: $title',
        taskId: drift.Value(taskId),
        projectId: drift.Value(projectId),
        isRead: const drift.Value(false),
      ),
    );
  }
}

/// ======================================================
/// TASK LIST PROVIDERS
/// ======================================================
final tasksProvider =
StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return TasksNotifier(repo, ref);
});

/// Project-specific tasks (USED BY ProjectDetailScreen)
final tasksByProjectProvider =
StreamProvider.family<List<Task>, int>((ref, projectId) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchTasks(projectId: projectId);
});

/// Filtered tasks (Task list screen)
final filteredTasksProvider =
StreamProvider.autoDispose<List<Task>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);

  final status = ref.watch(statusFilterProvider);
  final sortBy = ref.watch(sortByProvider);
  final overdue = ref.watch(overdueFilterProvider);
  final priority = ref.watch(priorityFilterProvider);
  final projectId = ref.watch(projectFilterProvider);

  List<String>? statuses;
  if (status != 'all') statuses = [status];

  DateTime? fromDate;
  DateTime? toDate;
  if (overdue) {
    fromDate = DateTime(1970);
    toDate = DateTime.now();
  }

  return repo.watchTasks(
    statuses: statuses,
    priority: priority,
    projectId: projectId,
    fromDate: fromDate,
    toDate: toDate,
    sortBy: sortBy == 'date'
        ? 'due_date_asc'
        : 'priority_desc',
  );
});

/// ======================================================
/// USERS
/// ======================================================
final allUsersProvider =
FutureProvider.autoDispose<List<User>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.select(db.users).get();
});

/// ======================================================
/// FILTER STATE PROVIDERS
/// ======================================================
final statusFilterProvider =
StateProvider<String>((ref) => 'all');

final sortByProvider =
StateProvider<String>((ref) => 'date');

final overdueFilterProvider =
StateProvider<bool>((ref) => false);

final priorityFilterProvider =
StateProvider<int?>((ref) => null);

final projectFilterProvider =
StateProvider<int?>((ref) => null);