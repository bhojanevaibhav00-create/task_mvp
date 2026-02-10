import 'package:drift/drift.dart';
import '../database/database.dart';

class SubtaskRepository {
  final AppDatabase db;

  SubtaskRepository(this.db);

  // 1. Fetch subtasks for a specific task
  Stream<List<Subtask>> watchSubtasks(int taskId) {
    return (db.select(db.subtasks)..where((t) => t.taskId.equals(taskId))).watch();
  }

  Future<List<Subtask>> getSubtasks(int taskId) {
    return (db.select(db.subtasks)..where((t) => t.taskId.equals(taskId))).get();
  }

  // 2. Create a subtask
  Future<int> addSubtask(SubtasksCompanion subtask) {
    return db.into(db.subtasks).insert(subtask);
  }

  // 3. Toggle completion status
  Future<bool> toggleSubtask(int subtaskId, bool isCompleted) {
    return (db.update(db.subtasks)..where((t) => t.id.equals(subtaskId)))
        .write(SubtasksCompanion(isCompleted: Value(isCompleted)))
        .then((rows) => rows > 0);
  }

  // 4. Delete a subtask
  Future<int> deleteSubtask(int subtaskId) {
    return (db.delete(db.subtasks)..where((t) => t.id.equals(subtaskId))).go();
  }

  /// =======================================================
  /// SPRINT 9 P0 FEATURES
  /// =======================================================

  // A) Bulk Action: Mark all subtasks for a task as done
  Future<void> markAllSubtasksDone(int taskId) async {
    await (db.update(db.subtasks)..where((t) => t.taskId.equals(taskId)))
        .write(const SubtasksCompanion(isCompleted: Value(true)));
  }

  // B) Accurate Progress Calculation logic
  // Formula: ((DoneTasks + DoneSubtasks) / (TotalTasks + TotalSubtasks)) * 100
  Future<double> getProjectProgress(int projectId) async {
    // Get all tasks in project
    final projectTasks = await (db.select(db.tasks)
          ..where((t) => t.projectId.equals(projectId)))
        .get();

    if (projectTasks.isEmpty) return 0.0;

    int totalItems = projectTasks.length;
    int completedItems = projectTasks.where((t) => t.status == 'Done').length;

    // Get all subtasks for those tasks
    final taskIds = projectTasks.map((t) => t.id).toList();
    final projectSubtasks = await (db.select(db.subtasks)
          ..where((t) => t.taskId.isIn(taskIds)))
        .get();

    totalItems += projectSubtasks.length;
    completedItems += projectSubtasks.where((s) => s.isCompleted).length;

    if (totalItems == 0) return 0.0;
    
    // Returns a value between 0.0 and 1.0 (multiply by 100 in UI)
    return completedItems / totalItems;
  }
}