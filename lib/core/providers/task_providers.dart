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
/// TASKS NOTIFIER (Handling Manual State Updates)
/// ======================================================
class TasksNotifier extends StateNotifier<List<Task>> {
  final TaskRepository _repository;

  TasksNotifier(this._repository) : super([]) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      state = await _repository.getAllTasks();
    } catch (_) {
      state = [];
    }
  }

  // Integration for Sprint 7: Support for assignee and projects
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

    await _repository.createTask(companion);
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _repository.updateTask(task);
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
    await loadTasks();
  }
}

/// ======================================================
/// FILTERED TASKS STREAM (BEST FOR UI WITH .when())
/// ======================================================
// This provider is a StreamProvider, use this in your Dashboard Widgets
final filteredTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);

  // Watching filter states for automatic UI updates
  final status = ref.watch(statusFilterProvider);
  final sortBy = ref.watch(sortByProvider);
  final overdue = ref.watch(overdueFilterProvider);
  final priority = ref.watch(priorityFilterProvider);
  final projectId = ref.watch(projectFilterProvider);

  List<String>? statuses;
  if (status != 'all') statuses = [status];

  // Logic for overdue filtering
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

/// ======================================================
/// COLLABORATION & USER PROVIDERS (NEW)
/// ======================================================
final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TasksNotifier(repository);
});

// To display team members on the Dashboard
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