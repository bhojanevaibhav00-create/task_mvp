import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:task_mvp/data/database/database.dart';
import 'package:task_mvp/data/repositories/task_repository.dart';
import 'package:task_mvp/data/models/enums.dart';
import 'package:task_mvp/core/providers/notification_providers.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Repository provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final notificationRepo = ref.read(notificationRepositoryProvider);
   return TaskRepository(db, notificationRepo);;
});

// Tasks state notifier
class TasksNotifier extends StateNotifier<List<Task>> {
  final TaskRepository _repository;

  TasksNotifier(this._repository) : super([]) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final tasks = await _repository.getAllTasks();
      state = tasks;
    } catch (e) {
      // Handle error - could add error state
      state = [];
    }
  }

  Future<void> addTask(
    String title,
    String description, {
    int priority = 1,
    DateTime? dueDate,
  }) async {
    final companion = TasksCompanion.insert(
      title: title,
      description: drift.Value(description.isEmpty ? null : description),
      priority: drift.Value(priority),
      status: drift.Value(TaskStatus.todo.name),
      dueDate: drift.Value(dueDate),
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

  List<Task> getFilteredTasks(String? status, String? sortBy) {
    List<Task> filtered = List.from(state);

    // Filter by status
    if (status != null && status != 'all') {
      filtered = filtered.where((task) => task.status == status).toList();
    }

    // Sort
    if (sortBy == 'title') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    } else if (sortBy == 'priority') {
      filtered.sort(
        (a, b) => (b.priority ?? 0).compareTo(a.priority ?? 0),
      ); // Higher priority first
    } else if (sortBy == 'date') {
      filtered.sort(
        (a, b) => b.id.compareTo(a.id),
      ); // Newer tasks first (higher id)
    }

    return filtered;
  }
}

// Tasks provider
final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TasksNotifier(repository);
});

// Filter and sort providers
final statusFilterProvider = StateProvider<String>((ref) => 'all');
final sortByProvider = StateProvider<String>((ref) => 'date');
final overdueFilterProvider = StateProvider<bool>((ref) => false);
final priorityFilterProvider = StateProvider<int?>((ref) => null);
final tagFilterProvider = StateProvider<int?>((ref) => null);
final projectFilterProvider = StateProvider<int?>((ref) => null);
final dateRangeStartProvider = StateProvider<DateTime?>((ref) => null);
final dateRangeEndProvider = StateProvider<DateTime?>((ref) => null);

// Filtered tasks provider
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

  // Map UI filters to Repository parameters
  List<String>? statuses;
  if (status != 'all') {
    statuses = [status];
  }

  String repoSort = 'updated_at_desc';
  if (sortBy == 'priority') repoSort = 'priority_desc';
  if (sortBy == 'date') repoSort = 'due_date_asc';

  DateTime? fromDate = start;
  DateTime? toDate = end;
  if (overdue) {
    fromDate = DateTime(1970); // Beginning of time
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

// Activity Logs Provider
final recentActivityProvider = FutureProvider.autoDispose<List<ActivityLog>>((
  ref,
) async {
  ref.watch(tasksProvider); // Refresh when tasks change
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getRecentActivity();
});
