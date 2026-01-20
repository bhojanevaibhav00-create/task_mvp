import 'package:drift/drift.dart';
import '../database/database.dart';

/// Repository for handling collaboration features (assignments, members).
class CollaborationRepository {
  final AppDatabase _db;

  CollaborationRepository(this._db);

  /// Adds a member to a project with a specific role.
  Future<void> addProjectMember(int projectId, int userId, String role) async {
    await _db
        .into(_db.projectMembers)
        .insert(
          ProjectMembersCompanion.insert(
            projectId: projectId,
            userId: userId,
            role: role,
            joinedAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrReplace,
        );

    await _logActivity('member_added', 'Member added', projectId: projectId);
  }

  /// Removes a member from a project.
  Future<void> removeProjectMember(int projectId, int userId) async {
    await (_db.delete(_db.projectMembers)..where(
          (m) => m.projectId.equals(projectId) & m.userId.equals(userId),
        ))
        .go();

    await _logActivity(
      'member_removed',
      'Member removed',
      projectId: projectId,
    );
  }

  /// Lists all members associated with a specific project.
  Future<List<ProjectMember>> listProjectMembers(int projectId) {
    return (_db.select(
      _db.projectMembers,
    )..where((m) => m.projectId.equals(projectId))).get();
  }

  /// Assigns a task to a specific user.
  Future<void> assignTask(int taskId, int userId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(assigneeId: Value(userId)),
    );

    await _logActivity('task_assigned', 'Task assigned', taskId: taskId);
  }

  /// Unassigns a task.
  Future<void> unassignTask(int taskId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      const TasksCompanion(assigneeId: Value(null)),
    );

    await _logActivity('task_unassigned', 'Task unassigned', taskId: taskId);
  }

  // --- Private Helpers ---

  Future<void> _logActivity(
    String action,
    String description, {
    int? taskId,
    int? projectId,
  }) async {
    await _db
        .into(_db.activityLogs)
        .insert(
          ActivityLogsCompanion.insert(
            action: action,
            description: Value(description),
            taskId: Value(taskId),
            projectId: Value(projectId),
            timestamp: Value(DateTime.now()),
          ),
        );
  }
}
