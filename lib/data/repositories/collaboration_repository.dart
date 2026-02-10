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
/// This repository acts as the bridge between Users, Project Members, and Notifications.
class CollaborationRepository {
  final AppDatabase _db;
  final NotificationRepository _notificationRepo;

  CollaborationRepository(this._db, this._notificationRepo);

  /// Fetches raw project member records for a specific project.
  Future<List<ProjectMember>> getProjectMembers(int projectId) async {
    return (_db.select(
      _db.projectMembers,
    )..where((t) => t.projectId.equals(projectId))).get();
  }

  /// ✅ FIXED: Added duplicate check and notification triggers using simplified strings
  /// This method ensures no user is added twice and logs the event for transparency.
  Future<void> addMember(
    int projectId,
    int userId, {
    ProjectRole role = ProjectRole.member,
  }) async {
    // 1. Manual Check to prevent duplicate entries (Enterprise Requirement)
    final existing = await (_db.select(_db.projectMembers)
          ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId)))
        .getSingleOrNull();

    if (existing != null) return;

    // 2. Insert new member with joinedAt timestamp
    await _db.into(_db.projectMembers).insert(
          ProjectMembersCompanion.insert(
            projectId: projectId,
            userId: userId,
            role: role.name,
            joinedAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    // 3. Trigger Activity Log for the audit trail
    await _logActivity(
      'member_added',
      'Member $userId added to project as ${role.label}',
      projectId: projectId,
    );

    // 4. ✅ FIXED: Trigger Notification using the refactored String-based parameters
    await _notificationRepo.addNotification(
      type: 'project',
      title: 'Added to Project',
      body: 'You have been added to a new project as ${role.label}',
    );
  }

  /// ✅ FIXED: Enhanced Role Safety and event triggers
  /// Prevents the last owner from being removed to avoid orphaned projects.
  Future<void> removeMember(int projectId, int userId, List<dynamic> allMembers) async {
    final member = await (_db.select(_db.projectMembers)
          ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId)))
        .getSingleOrNull();

    if (member == null) return;

    // 1. Enforce Role Safety: Cannot remove the last owner
    if (member.role.toLowerCase() == 'owner') {
      final ownersCount = await _countOwners(projectId);
      if (ownersCount <= 1) {
        throw Exception(
          'Role Safety Error: Cannot remove the only owner of the project. Assign another owner first.',
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

    // 4. ✅ FIXED: Trigger Notification using simplified parameters
    await _notificationRepo.addNotification(
      type: 'project',
      title: 'Project Membership Updated',
      body: 'A member has been removed from the project.',
    );
  }

  /// Lists all members associated with a specific project, including user details.
  /// Uses a relational JOIN to fetch user names and emails alongside membership data.
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

  /// Assigns a task to a specific user.
  Future<void> assignTask(int taskId, int userId) async {
    final task = await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(taskId))).getSingleOrNull();
    
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

    // ✅ FIXED: Using simplified notification call
    await _notificationRepo.addNotification(
      type: 'assignment',
      title: 'Task Assigned',
      body: 'Task "${task.title}" has been assigned to you.',
    );
  }

  /// Updates a member's role (Admin, Member, Owner) with Safety Checks.
  Future<void> updateMemberRole(
    int projectId,
    int userId,
    ProjectRole newRole,
  ) async {
    // Constraint: Cannot downgrade the last owner
    if (newRole != ProjectRole.owner) {
      final member = await (_db.select(_db.projectMembers)
            ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId)))
          .getSingleOrNull();

      if (member != null && member.role.toLowerCase() == 'owner') {
        final ownersCount = await _countOwners(projectId);
        if (ownersCount <= 1) {
          throw Exception('Role Safety Error: Cannot downgrade the only owner of the project.');
        }
      }
    }

    await (_db.update(_db.projectMembers)
          ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId)))
        .write(ProjectMembersCompanion(role: Value(newRole.name)));

    await _logActivity(
      'role_updated',
      'User $userId role updated to ${newRole.label}',
      projectId: projectId,
    );
  }

  /// Unassigns a task and removes the assigneeId link.
  Future<void> unassignTask(int taskId) async {
    final task = await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(taskId))).getSingleOrNull();
    
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

    // ✅ FIXED: Using simplified notification call
    await _notificationRepo.addNotification(
      type: 'assignment',
      title: 'Task Unassigned',
      body: 'Task "${task.title}" is no longer assigned to you.',
    );
  }

  /// Lists users who are NOT currently members of the specified project.
  /// Useful for the "Add Member" dropdown logic.
  Future<List<User>> listAvailableUsersNotInProject(int projectId) {
    final membersSubquery = _db.selectOnly(_db.projectMembers)
      ..addColumns([_db.projectMembers.userId])
      ..where(_db.projectMembers.projectId.equals(projectId));

    return (_db.select(_db.users)
          ..where((u) => u.id.isNotInQuery(membersSubquery)))
        .get();
  }

  /// Fetches a single user record by ID.
  Future<User?> getUserById(int userId) {
    return (_db.select(_db.users)..where((u) => u.id.equals(userId))).getSingleOrNull();
  }

  /// Searches for users by name (for collaboration search features).
  Future<List<User>> searchUsers(String query) {
    return (_db.select(_db.users)..where((u) => u.name.contains(query))).get();
  }

  // --- Private Helpers for Audit and Safety ---

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