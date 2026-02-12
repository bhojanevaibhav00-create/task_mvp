import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import 'package:task_mvp/data/database/database.dart';
import 'package:task_mvp/data/repositories/task_repository.dart';
import 'package:task_mvp/data/repositories/notification_repository.dart';
import 'package:task_mvp/data/repositories/subtask_repository.dart';
import 'package:task_mvp/data/repositories/comment_repository.dart'; // ✅ Sprint 9 New
import 'package:task_mvp/core/services/reminder_service.dart';
import 'package:task_mvp/data/models/enums.dart';
import 'package:task_mvp/core/providers/database_provider.dart';

/// ======================================================
/// 1. REPOSITORY PROVIDERS
/// ======================================================

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NotificationRepository(db);
});

final reminderServiceProvider = Provider<ReminderService>((ref) {
  final db = ref.watch(databaseProvider);
  return ReminderService(db);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  final reminderService = ref.watch(reminderServiceProvider);
  return TaskRepository(db, notificationRepo, reminderService);
});

final subtaskRepositoryProvider = Provider<SubtaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SubtaskRepository(db);
});

// ✅ New Repository Provider for Sprint 9 Collaboration
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  return CommentRepository(db, notificationRepo);
});

/// ======================================================
/// 2. TASKS NOTIFIER (State Logic & Actions)
/// ======================================================

class TasksNotifier extends StateNotifier<List<Task>> {
  final TaskRepository _repository;
  final Ref _ref;

  TasksNotifier(this._repository, this._ref) : super([]) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final tasks = await _repository.getAllTasks();
      state = tasks;
    } catch (_) {
      state = [];
    }
  }

  Future<void> addTask(
    String title,
    String description, {
    int priority = 1,
    DateTime? dueDate,
    int? assigneeId,
    int? projectId,
  }) async {
    final companion = TasksCompanion.insert(
      title: title,
      description: drift.Value(description.isEmpty ? null : description),
      priority: drift.Value(priority),
      status: drift.Value(TaskStatus.todo.name),
      dueDate: drift.Value(dueDate),
      assigneeId: drift.Value(assigneeId),
      projectId: drift.Value(projectId),
      createdAt: drift.Value(DateTime.now()),
    );

    final taskId = await _repository.createTask(companion);
    if (assigneeId != null) {
      await _triggerCollabEvents(taskId, "Assigned: $title", projectId);
    }
    await loadTasks();
    _ref.invalidate(projectProgressProvider);
  }

  Future<void> updateTask(Task task) async {
    final oldTask = state.firstWhere(
      (t) => t.id == task.id,
      orElse: () => task,
    );
    await _repository.updateTask(task);

    if (task.assigneeId != null && task.assigneeId != oldTask.assigneeId) {
      await _triggerCollabEvents(
        task.id,
        "New assignment: ${task.title}",
        task.projectId,
      );
    }
    await loadTasks();
    _ref.invalidate(projectProgressProvider);
  }

  Future<void> assignTask(int taskId, int? userId) async {
    final task = state.firstWhere((t) => t.id == taskId);
    final updatedTask = task.copyWith(assigneeId: drift.Value(userId));

    await _repository.updateTask(updatedTask);
    await _triggerCollabEvents(
      taskId,
      userId != null ? "Task Assigned: ${task.title}" : "Task Unassigned",
      task.projectId,
    );

    _ref.invalidate(filteredTasksProvider);
    _ref.invalidate(projectTasksProvider);
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
    state = state.where((t) => t.id != id).toList();
    _ref.invalidate(tasksProvider);
    _ref.invalidate(projectProgressProvider);
  }

  Future<void> _triggerCollabEvents(int taskId, String msg, int? pId) async {
    try {
      final db = _ref.read(databaseProvider);
      await db
          .into(db.activityLogs)
          .insert(
            ActivityLogsCompanion.insert(
              action: 'Task Assignment',
              description: drift.Value(msg),
              taskId: drift.Value(taskId),
              projectId: drift.Value(pId),
              timestamp: drift.Value(DateTime.now()),
            ),
          );
      await db
          .into(db.notifications)
          .insert(
            NotificationsCompanion.insert(
              type: 'assignment',
              title: 'New Assignment',
              message: msg,
              taskId: drift.Value(taskId),
              projectId: drift.Value(pId),
              createdAt: drift.Value(DateTime.now()),
              isRead: const drift.Value(false),
            ),
          );
    } catch (e) {
      // Prevent crash if FK constraint fails or DB is locked
    }
  }
}

/// ======================================================
/// 3. SPRINT 9: SUBTASKS, PROGRESS & COLLABORATION
/// ======================================================

// ✅ Watch subtasks for real-time checklist updates
final subtasksStreamProvider = StreamProvider.family<List<Subtask>, int>((
  ref,
  taskId,
) {
  final repo = ref.watch(subtaskRepositoryProvider);
  return repo.watchSubtasks(taskId);
});

// ✅ Accurate Project Progress calculation
final projectProgressProvider = FutureProvider.family<double, int>((
  ref,
  projectId,
) async {
  final repo = ref.watch(subtaskRepositoryProvider);
  ref.watch(tasksProvider);
  return await repo.getProjectProgress(projectId);
});

// ✅ SPRINT 9 P0: Real-time Comment Stream with User Data
final taskCommentsProvider = StreamProvider.family<List<CommentWithUser>, int>((
  ref,
  taskId,
) {
  final repo = ref.watch(commentRepositoryProvider);
  return repo.watchComments(taskId);
});

/// ======================================================
/// 4. UI & STREAM PROVIDERS
/// ======================================================

final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TasksNotifier(repository, ref);
});

final filteredTasksProvider =
    StreamProvider.autoDispose<List<TaskWithAssignee>>((ref) {
      final repository = ref.watch(taskRepositoryProvider);

      final status = ref.watch(statusFilterProvider);
      final sortBy = ref.watch(sortByProvider);
      final dueBucket = ref.watch(dueBucketFilterProvider);
      final priority = ref.watch(priorityFilterProvider);
      final projectId = ref.watch(projectFilterProvider);

      List<String>? statusList = status != 'all' ? [status] : null;
      DateTime? fromDate;
      DateTime? toDate;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      if (dueBucket == "Today") {
        fromDate = todayStart;
        toDate = todayEnd;
      } else if (dueBucket == "Overdue") {
        fromDate = DateTime(1970);
        toDate = todayStart.subtract(const Duration(seconds: 1));
      } else if (dueBucket == "Upcoming") {
        fromDate = todayEnd.add(const Duration(seconds: 1));
        toDate = DateTime(2100);
      }

      return repository.watchTasksWithAssignee(
        statuses: statusList,
        priority: priority,
        projectId: projectId,
        fromDate: fromDate,
        toDate: toDate,
        sortBy: sortBy == 'priority' ? 'priority_desc' : 'due_date_asc',
      );
    });

final projectTasksProvider = StreamProvider.family
    .autoDispose<List<TaskWithAssignee>, int>((ref, projectId) {
      final repository = ref.watch(taskRepositoryProvider);
      final sortType = ref.watch(projectSortProvider);

      return repository.watchTasksWithAssignee(
        projectId: projectId,
        sortBy: sortType == 'priority' ? 'priority_desc' : 'due_date_asc',
      );
    });

final allUsersProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.select(db.users).get();
});

/// ======================================================
/// 5. FILTER & SORT STATE
/// ======================================================

final statusFilterProvider = StateProvider<String>((ref) => 'all');
final sortByProvider = StateProvider<String>((ref) => 'date');
final dueBucketFilterProvider = StateProvider<String?>((ref) => null);
final priorityFilterProvider = StateProvider<int?>((ref) => null);
final projectFilterProvider = StateProvider<int?>((ref) => null);
final projectSortProvider = StateProvider.autoDispose<String>((ref) => 'date');
