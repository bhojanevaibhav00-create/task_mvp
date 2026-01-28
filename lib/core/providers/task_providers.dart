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
/// NOTIFICATION REPOSITORY
/// ======================================================
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NotificationRepository(db);
});

/// ======================================================
/// REMINDER SERVICE
/// ======================================================
final reminderServiceProvider = Provider<ReminderService>((ref) {
  final db = ref.watch(databaseProvider);
  return ReminderService(db);
});

/// ======================================================
/// COLLABORATION REPOSITORY
/// ======================================================
final collaborationRepositoryProvider = Provider<CollaborationRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  return CollaborationRepository(db, notificationRepo);
});

/// ======================================================
/// TASK REPOSITORY
/// ======================================================
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  final reminderService = ref.watch(reminderServiceProvider);

  return TaskRepository(db, notificationRepo, reminderService);
});

/// ======================================================
/// TASKS NOTIFIER (FIXED FOR SPRINT 6)
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

  // FIX: Added assigneeId and projectId to support Collaboration Wiring
  Future<void> addTask(
    String title,
    String description, {
    int priority = 1,
    DateTime? dueDate,
    int? assigneeId, // <--- Successfully added
    int? projectId,  // <--- Successfully added
  }) async {
    final companion = TasksCompanion.insert(
      title: title,
      description: drift.Value(description.isEmpty ? null : description),
      priority: drift.Value(priority),
      status: drift.Value(TaskStatus.todo.name),
      dueDate: drift.Value(dueDate),
      assigneeId: drift.Value(assigneeId), // <--- Now mapped to DB
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

  Future<void> deleteAllTasks() async {
    await _repository.deleteAllTasks();
    await loadTasks();
  }

  Future<void> seedData() async {
    await _repository.seedDatabase();
    await loadTasks();
  }
}

/// ======================================================
/// TASKS PROVIDER
/// ======================================================
final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TasksNotifier(repository);
});

/// ======================================================
/// FILTER PROVIDERS
/// ======================================================
final statusFilterProvider = StateProvider<String>((ref) => 'all');
final sortByProvider = StateProvider<String>((ref) => 'date');
final overdueFilterProvider = StateProvider<bool>((ref) => false);
final priorityFilterProvider = StateProvider<int?>((ref) => null);
final tagFilterProvider = StateProvider<int?>((ref) => null);
final projectFilterProvider = StateProvider<int?>((ref) => null);
final dateRangeStartProvider = StateProvider<DateTime?>((ref) => null);
final dateRangeEndProvider = StateProvider<DateTime?>((ref) => null);

/// ======================================================
/// FILTERED TASKS STREAM
/// ======================================================
final filteredTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);

  final status = ref.watch(statusFilterProvider);
  final sortBy = ref.watch(sortByProvider);
  final overdue = ref.watch(overdueFilterProvider);
  final priority = ref.watch(priorityFilterProvider);
  final tagId = ref.watch(tagFilterProvider);
  final projectId = ref.watch(projectFilterProvider);
  final start = ref.watch(dateRangeStartProvider);
  final end = ref.watch(dateRangeEndProvider);

  List<String>? statuses;
  if (status != 'all') statuses = [status];

  String repoSort = 'updated_at_desc';
  if (sortBy == 'priority') repoSort = 'priority_desc';
  if (sortBy == 'date') repoSort = 'due_date_asc';

  DateTime? fromDate = start;
  DateTime? toDate = end;

  if (overdue) {
    fromDate = DateTime(1970);
    toDate = DateTime.now();
  }

  return repository.watchTasks(
    statuses: statuses,
    sortBy: repoSort,
    priority: priority,
    tagId: tagId,
    projectId: projectId,
    fromDate: fromDate,
    toDate: toDate,
  );
});

/// ======================================================
/// ACTIVITY LOGS
/// ======================================================
final recentActivityProvider = FutureProvider.autoDispose<List<ActivityLog>>((
  ref,
) async {
  ref.watch(tasksProvider);
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getRecentActivity();
});