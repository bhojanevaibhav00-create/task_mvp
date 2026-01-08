import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../../domains/entities/task_entity.dart';
import '../../domains/enums/task_priority.dart';
import '../../domains/enums/task_status.dart';
import '../database/app_database.dart';

class TaskRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  TaskRepository(this.db);

  // CREATE
  Future<void> createTask({
    required String title,
    required String projectId,
    String? assigneeId,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: _uuid.v4(),
            title: title,
            status: TaskStatus.todo.value,
            priority: priority.value,
            projectId: projectId,
            assigneeId: Value(assigneeId),
            createdAt: DateTime.now(),
          ),
        );
  }

  // READ (STREAM)
  Stream<List<TaskEntity>> watchTasks() {
    return db
        .select(db.tasks)
        .watch()
        .map((rows) => rows.map(_mapToEntity).toList());
  }

  // UPDATE STATUS
  Future<void> updateStatus(String taskId, TaskStatus status) async {
    await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(status: Value(status.value)),
    );
  }

  // DELETE
  Future<void> deleteTask(String taskId) async {
    await (db.delete(db.tasks)..where((t) => t.id.equals(taskId))).go();
  }

  // FILTER BY STATUS
  Stream<List<TaskEntity>> watchByStatus(TaskStatus status) {
    return (db.select(db.tasks)..where((t) => t.status.equals(status.value)))
        .watch()
        .map((rows) => rows.map(_mapToEntity).toList());
  }

  // MAPPER (IMPORTANT)
  TaskEntity _mapToEntity(Task row) {
    return TaskEntity(
      id: row.id,
      title: row.title,
      description: row.description,
      status: TaskStatusX.fromString(row.status),
      priority: TaskPriorityX.fromString(row.priority),
      projectId: row.projectId,
      assigneeId: row.assigneeId,
      createdAt: row.createdAt,
    );
  }
}
