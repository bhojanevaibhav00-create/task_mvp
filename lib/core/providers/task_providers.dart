import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:task_mvp/data/database/database.dart';
import 'package:task_mvp/data/repositories/task_repository.dart';
import 'package:task_mvp/data/repositories/notification_repository.dart';
import 'package:task_mvp/data/repositories/collaboration_repository.dart';
import 'package:task_mvp/data/models/enums.dart';
import 'package:task_mvp/core/services/reminder_service.dart';

/// ======================================================
/// DATABASE PROVIDER
/// ======================================================
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// ======================================================
/// REPOSITORY PROVIDERS
/// ======================================================
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NotificationRepository(db);
});

final reminderServiceProvider = Provider<ReminderService>((ref) {
  final db = ref.watch(databaseProvider);
  return ReminderService(db);
});

final collaborationRepositoryProvider = Provider<CollaborationRepository>((ref) {
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
/// ======================================================
/// TASKS NOTIFIER (Handling Activity Logs & Notifications)
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

  // --- Sprint 7: Task Creation with Activity + Notification ---
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

    // 🚀 FIXED: Trigger Collab Events directly via DB
    if (assigneeId != null) {
      await _triggerCollabEvents(taskId, "Task Assigned: $title", projectId);
    }

    await loadTasks();
  }

  // --- Sprint 7: Update with Assignment Change Detection ---
  Future<void> updateTask(Task task) async {
    // Find the old state to see if assignee changed
    final oldTask = state.firstWhere((t) => t.id == task.id, orElse: () => task);
    
    await _repository.updateTask(task);

    // 🚀 FIXED: Trigger events if a new person is assigned
    if (task.assigneeId != null && task.assigneeId != oldTask.assigneeId) {
      await _triggerCollabEvents(task.id, "You were assigned to: ${task.title}", task.projectId);
    }

    await loadTasks();
  }

  /// 🛡️ Private helper to log Activity and create Notifications
  /// Directly uses the Database to avoid 'createNotification' method errors
  Future<void> _triggerCollabEvents(int taskId, String msg, int? pId) async {
    final db = _ref.read(databaseProvider);

    // 1. Insert into Activity Table
    await db.into(db.activityLogs).insert(ActivityLogsCompanion.insert(
      action: 'Task Assignment',
      description: drift.Value(msg),
      taskId: drift.Value(taskId),
      projectId: drift.Value(pId),
      timestamp: drift.Value(DateTime.now()),
    ));

    // 2. Insert into Notifications Table (Fixed error here)
    await db.into(db.notifications).insert(NotificationsCompanion.insert(
      type: 'assignment',
      title: 'New Assignment',
      message: msg,
      taskId: drift.Value(taskId),
      projectId: drift.Value(pId),
      createdAt: drift.Value(DateTime.now()),
      isRead: const drift.Value(false), // Ensure default value is set
    ));
  }

  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
    await loadTasks();
  }
}

/// ======================================================
/// TASKS PROVIDER
/// ======================================================
final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TasksNotifier(repository, ref); 
});
final filteredTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
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

  return repository.watchTasks(
    statuses: statuses,
    sortBy: sortBy == 'date' ? 'due_date_asc' : 'priority_desc',
    priority: priority,
    projectId: projectId,
    fromDate: fromDate,
    toDate: toDate,
  );
});

final allUsersProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.select(db.users).get();
});

/// ======================================================
/// FILTER STATE PROVIDERS
/// ======================================================
final statusFilterProvider = StateProvider<String>((ref) => 'all');
final sortByProvider = StateProvider<String>((ref) => 'date');
final overdueFilterProvider = StateProvider<bool>((ref) => false);
final priorityFilterProvider = StateProvider<int?>((ref) => null);
final projectFilterProvider = StateProvider<int?>((ref) => null);