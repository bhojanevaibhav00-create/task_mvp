import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:task_mvp/data/database/database.dart';
import 'package:task_mvp/data/repositories/task_repository.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Repository provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskRepository(db);
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
      status: drift.Value('pending'),
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
    final now = DateTime.now();
    final tasks = [
      TasksCompanion.insert(
        title: 'Complete Project Proposal',
        description: const drift.Value(
          'Draft the initial proposal for the client meeting.',
        ),
        priority: const drift.Value(3), // High
        status: const drift.Value('pending'),
        dueDate: drift.Value(now.add(const Duration(days: 2))),
      ),
      TasksCompanion.insert(
        title: 'Buy Groceries',
        description: const drift.Value('Milk, Bread, Eggs, Coffee'),
        priority: const drift.Value(1), // Low
        status: const drift.Value('pending'),
        dueDate: drift.Value(now.add(const Duration(hours: 4))),
      ),
      TasksCompanion.insert(
        title: 'Submit Tax Report',
        description: const drift.Value('Quarterly tax submission.'),
        priority: const drift.Value(3),
        status: const drift.Value('pending'),
        dueDate: drift.Value(now.subtract(const Duration(days: 2))), // Overdue
      ),
      TasksCompanion.insert(
        title: 'Team Meeting',
        description: const drift.Value('Weekly sync with the dev team.'),
        priority: const drift.Value(2),
        status: const drift.Value('completed'),
        dueDate: drift.Value(now.subtract(const Duration(days: 1))),
      ),
    ];

    for (var task in tasks) {
      await _repository.createTask(task);
    }
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

// Filtered tasks provider
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final statusFilter = ref.watch(statusFilterProvider);
  final sortBy = ref.watch(sortByProvider);
  final overdueFilter = ref.watch(overdueFilterProvider);

  List<Task> filtered = List.from(tasks);

  // Filter by overdue
  if (overdueFilter) {
    final now = DateTime.now();
    filtered = filtered.where((task) {
      return task.status != 'completed' &&
          task.dueDate != null &&
          task.dueDate!.isBefore(now);
    }).toList();
  } else {
    // Filter by status (only if not filtering by overdue)
    if (statusFilter != 'all') {
      filtered = filtered.where((task) => task.status == statusFilter).toList();
    }
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
});
