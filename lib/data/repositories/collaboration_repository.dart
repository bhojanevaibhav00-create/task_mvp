import 'dart:async';

/// Repository for handling collaboration features (assignments, members).
/// This is a stub implementation for Phase-1.
class CollaborationRepository {
  // TODO: Inject AppDatabase here
  // final AppDatabase _db;
  // CollaborationRepository(this._db);

  /// Assigns a task to a user (or unassigns if [userId] is null).
  /// Should also create an ActivityLog entry for "Assignee changed".
  Future<void> assignTask(int taskId, int? userId) async {
    // Implementation Stub:
    // 1. await _db.update(_db.tasks).replace(task.copyWith(assigneeId: Value(userId)));
    // 2. await _db.into(_db.activityLogs).insert(ActivityLogsCompanion(... action: 'Assignee changed'));
    throw UnimplementedError('assignTask not implemented');
  }

  /// Lists all members associated with a specific project.
  /// Returns a list of the generated `ProjectMember` data class.
  Future<List<dynamic>> listProjectMembers(int projectId) async {
    // Implementation Stub:
    // return (_db.select(_db.projectMembers)..where((m) => m.projectId.equals(projectId))).get();
    throw UnimplementedError('listProjectMembers not implemented');
  }
}
