import 'package:drift/drift.dart';
import 'package:task_mvp/data/database/database.dart';
import 'package:task_mvp/data/models/project_role.dart';
import 'package:task_mvp/data/repositories/notification_repository.dart';

/// Data Transfer Object for Project Member with User details
class ProjectMemberWithUser {
  final ProjectMember member;
  final User user;

  ProjectMemberWithUser({required this.member, required this.user});
}

/// Repository for handling collaboration features (assignments, members).
class CollaborationRepository {
  final AppDatabase _db;
  final NotificationRepository _notificationRepo;

  CollaborationRepository(this._db, this._notificationRepo);

  /// Fetches raw project member records for a specific project.
  Future<List<ProjectMember>> getProjectMembers(int projectId) async {
    return (_db.select(_db.projectMembers)
      ..where((t) => t.projectId.equals(projectId))).get();
  }

  /// Ensures no user is added twice and triggers a notification.
  Future<void> addMember(
    int projectId,
    int userId, {
    ProjectRole role = ProjectRole.member,
  }) async {
    // 1. Manual Check to prevent duplicate entries
    final existing = await (_db.select(_db.projectMembers)
          ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId)))
        .getSingleOrNull();

    if (existing != null) return;

    // 2. Insert new member
    await _db.into(_db.projectMembers).insert(
          ProjectMembersCompanion.insert(
            projectId: projectId,
            userId: userId,
            role: role.name,
            joinedAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    // 3. Trigger Activity Log
    await _logActivity(
      'member_added',
      'Member $userId added to project as ${role.label}',
      projectId: projectId,
    );

    // 4. ✅ ALIGNED: Uses 'message' and passes projectId context
    await _notificationRepo.addNotification(
      type: 'project',
      title: 'Added to Project',
      message: 'You have been added to a new project as ${role.label}',
      projectId: projectId,
    );
  }

  /// Prevents the last owner from being removed.
  Future<void> removeMember(int projectId, int userId, List<dynamic> allMembers) async {
    final member = await (_db.select(_db.projectMembers)
          ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId)))
        .getSingleOrNull();

    if (member == null) return;

    // 1. Enforce Role Safety
    if (member.role.toLowerCase() == 'owner') {
      final ownersCount = await _countOwners(projectId);
      if (ownersCount <= 1) {
        throw Exception(
          'Role Safety Error: Cannot remove the only owner of the project.',
        );
      }
    }

    // 2. Perform deletion
    await (_db.delete(_db.projectMembers)
          ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId)))
        .go();

    // 3. Trigger Activity Log
    await _logActivity(
      'member_removed',
      'Member $userId removed from project',
      projectId: projectId,
    );

    // 4. ✅ ALIGNED: Uses 'message'
    await _notificationRepo.addNotification(
      type: 'project',
      title: 'Project Membership Updated',
      message: 'A member has been removed from the project.',
      projectId: projectId,
    );
  }

  /// Relational JOIN to fetch user names alongside membership data.
  Future<List<ProjectMemberWithUser>> listProjectMembers(int projectId) async {
    final query = _db.select(_db.projectMembers).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.projectMembers.userId)),
    ])..where(_db.projectMembers.projectId.equals(projectId));

    final rows = await query.get();
    return rows.map((row) {
      return ProjectMemberWithUser(
        member: row.readTable(_db.projectMembers),
        user: row.readTable(_db.users),
      );
    }).toList();
  }

  /// Assigns a task to a user and notifies them.
  Future<void> assignTask(int taskId, int userId) async {
    final task = await (_db.select(_db.tasks)
      ..where((t) => t.id.equals(taskId))).getSingleOrNull();
    
    if (task == null) return;

    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(assigneeId: Value(userId)),
    );

    await _logActivity(
      'task_assigned',
      'Task assigned to user $userId',
      taskId: taskId,
      projectId: task.projectId,
    );

    // ✅ ALIGNED: Pass taskId for direct navigation
    await _notificationRepo.addNotification(
      type: 'assignment',
      title: 'Task Assigned',
      message: 'Task "${task.title}" has been assigned to you.',
      taskId: taskId,
      projectId: task.projectId,
    );
  }

  /// Unassigns a task and removed the link.
  Future<void> unassignTask(int taskId) async {
    final task = await (_db.select(_db.tasks)
      ..where((t) => t.id.equals(taskId))).getSingleOrNull();
    
    if (task == null) return;

    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      const TasksCompanion(assigneeId: Value(null)),
    );

    await _logActivity(
      'task_unassigned',
      'Task unassigned',
      taskId: taskId,
      projectId: task.projectId,
    );

    // ✅ ALIGNED: Pass taskId
    await _notificationRepo.addNotification(
      type: 'assignment',
      title: 'Task Unassigned',
      message: 'Task "${task.title}" is no longer assigned to you.',
      taskId: taskId,
      projectId: task.projectId,
    );
  }

  /// For the "Add Member" dropdown logic.
  Future<List<User>> listAvailableUsersNotInProject(int projectId) {
    final membersSubquery = _db.selectOnly(_db.projectMembers)
      ..addColumns([_db.projectMembers.userId])
      ..where(_db.projectMembers.projectId.equals(projectId));

    return (_db.select(_db.users)
          ..where((u) => u.id.isNotInQuery(membersSubquery)))
        .get();
  }

  // --- Private Helpers ---

  Future<int> _countOwners(int projectId) async {
    final countExp = _db.projectMembers.userId.count();
    final query = _db.selectOnly(_db.projectMembers)
      ..addColumns([countExp])
      ..where(
        _db.projectMembers.projectId.equals(projectId) &
            _db.projectMembers.role.equals('owner'),
      );

    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  Future<void> _logActivity(
    String action,
    String description, {
    int? taskId,
    int? projectId,
  }) async {
    await _db.into(_db.activityLogs).insert(
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