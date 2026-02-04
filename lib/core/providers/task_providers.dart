import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:task_mvp/data/database/database.dart';
import 'package:task_mvp/data/repositories/task_repository.dart';
import 'package:task_mvp/data/repositories/notification_repository.dart';
import 'package:task_mvp/data/repositories/collaboration_repository.dart';
import 'package:task_mvp/data/models/enums.dart';
import 'package:task_mvp/core/services/reminder_service.dart';

/// ======================================================
/// 1. DATABASE PROVIDER (The Source of Truth)
/// ======================================================
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// ======================================================
/// 2. REPOSITORY PROVIDERS
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
/// 3. TASKS NOTIFIER (State Logic)
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
      await _triggerCollabEvents(taskId, "Task Assigned: $title", projectId);
    }
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    final oldTask = state.firstWhere((t) => t.id == task.id, orElse: () => task);
    await _repository.updateTask(task);

    if (task.assigneeId != null && task.assigneeId != oldTask.assigneeId) {
      await _triggerCollabEvents(task.id, "New assignment: ${task.title}", task.projectId);
    }
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
    state = state.where((t) => t.id != id).toList();
    _ref.invalidate(tasksProvider); 
  }

  Future<void> _triggerCollabEvents(int taskId, String msg, int? pId) async {
    final db = _ref.read(databaseProvider);
    await db.into(db.activityLogs).insert(ActivityLogsCompanion.insert(
      action: 'Task Assignment',
      description: drift.Value(msg),
      taskId: drift.Value(taskId),
      projectId: drift.Value(pId),
      timestamp: drift.Value(DateTime.now()),
    ));

    await db.into(db.notifications).insert(NotificationsCompanion.insert(
      type: 'assignment',
      title: 'New Assignment',
      message: msg,
      taskId: drift.Value(taskId),
      projectId: drift.Value(pId),
      createdAt: drift.Value(DateTime.now()),
      isRead: const drift.Value(false),
    ));
  }
}

/// ======================================================
/// 4. UI & STREAM PROVIDERS
/// ======================================================

final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TasksNotifier(repository, ref); 
});

/// ✅ FIXED GLOBAL TASK LIST (Dashboard)
final filteredTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  
  // 1. Watch UI Filter States
  final status = ref.watch(statusFilterProvider);
  final sortBy = ref.watch(sortByProvider);
  final dueBucket = ref.watch(dueBucketFilterProvider); 
  final priority = ref.watch(priorityFilterProvider);
  final projectId = ref.watch(projectFilterProvider);

  // 2. FIXED: Status Mapping (Wraps single string selection in a List for Repository)
  List<String>? statusList;
  if (status != 'all') {
    statusList = [status];
  }

  // 3. FIXED: Due Date Logic (Calculating correct Date Windows)
  DateTime? fromDate;
  DateTime? toDate;

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

  if (dueBucket == "Today") {
    fromDate = todayStart;
    toDate = todayEnd;
  } else if (dueBucket == "Overdue") {
    fromDate = DateTime(1970); // Past
    toDate = todayStart.subtract(const Duration(seconds: 1));
  } else if (dueBucket == "Upcoming") {
    fromDate = todayEnd.add(const Duration(seconds: 1));
    toDate = DateTime(2100); // Future
  }

  // 4. Execute the Watch with correct parameters
  return repository.watchTasks(
    statuses: statusList,
    sortBy: sortBy == 'priority' ? 'priority_desc' : 'due_date_asc',
    priority: priority,
    projectId: projectId,
    fromDate: fromDate,
    toDate: toDate,
  );
});

final projectTasksProvider = StreamProvider.family.autoDispose<List<Task>, int>((ref, projectId) {
  final db = ref.watch(databaseProvider);
  final sortType = ref.watch(projectSortProvider);

  final query = db.select(db.tasks)..where((t) => t.projectId.equals(projectId));
  
  query.orderBy([
    (t) => drift.OrderingTerm(
      expression: sortType == 'priority' ? t.priority : t.dueDate,
      mode: drift.OrderingMode.asc,
    ),
  ]);

  return query.watch();
});

final allUsersProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.select(db.users).get();
});

/// ======================================================
/// 5. FILTER & SORT STATE PROVIDERS
/// ======================================================
final statusFilterProvider = StateProvider<String>((ref) => 'all');
final sortByProvider = StateProvider<String>((ref) => 'date');
final dueBucketFilterProvider = StateProvider<String?>((ref) => null); 
final priorityFilterProvider = StateProvider<int?>((ref) => null);
final projectFilterProvider = StateProvider<int?>((ref) => null);
final projectSortProvider = StateProvider.autoDispose<String>((ref) => 'date');