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

  Future<List<ProjectMember>> getProjectMembers(int projectId) async {
    return (_db.select(
      _db.projectMembers,
    )..where((t) => t.projectId.equals(projectId))).get();
  }

  /// ✅ FIXED: Added duplicate check and notification triggers
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

    // 4. Trigger Notification for the added user
    await _notificationRepo.addNotification(
      NotificationsCompanion.insert(
        type: 'project',
        title: 'Added to Project',
        message: 'You have been added to a new project as ${role.label}',
        projectId: Value(projectId),
      ),
    );
  }

  /// ✅ FIXED: Enhanced Role Safety and event triggers
  Future<void> removeMember(int projectId, int userId) async {
    final member = await (_db.select(_db.projectMembers)
          ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId)))
        .getSingleOrNull();

    if (member == null) return;

    // 1. Enforce Role Safety: Cannot remove the last owner
    if (member.role == ProjectRole.owner.name) {
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

    // 4. Trigger Notification
    await _notificationRepo.addNotification(
      NotificationsCompanion.insert(
        type: 'project',
        title: 'Project Membership Updated',
        message: 'A member has been removed from the project.',
        projectId: Value(projectId),
      ),
    );
  }

  /// Lists all members associated with a specific project, including user details.
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

    await _notificationRepo.addNotification(
      NotificationsCompanion.insert(
        type: 'assignment',
        title: 'Task Assigned',
        message: 'Task "${task.title}" assigned to user $userId',
        taskId: Value(taskId),
        projectId: Value(task.projectId),
      ),
    );
  }

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

      if (member != null && member.role == ProjectRole.owner.name) {
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

  /// Unassigns a task.
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

    await _notificationRepo.addNotification(
      NotificationsCompanion.insert(
        type: 'assignment',
        title: 'Task Unassigned',
        message: 'Task "${task.title}" unassigned',
        taskId: Value(taskId),
        projectId: Value(task.projectId),
      ),
    );
  }

  /// Lists users who are NOT currently members of the specified project.
  Future<List<User>> listAvailableUsersNotInProject(int projectId) {
    final membersSubquery = _db.selectOnly(_db.projectMembers)
      ..addColumns([_db.projectMembers.userId])
      ..where(_db.projectMembers.projectId.equals(projectId));

    return (_db.select(_db.users)
          ..where((u) => u.id.isNotInQuery(membersSubquery)))
        .get();
  }

  /// Fetches a single user by ID.
  Future<User?> getUserById(int userId) {
    return (_db.select(_db.users)..where((u) => u.id.equals(userId))).getSingleOrNull();
  }

  /// Searches for users by name.
  Future<List<User>> searchUsers(String query) {
    return (_db.select(_db.users)..where((u) => u.name.contains(query))).get();
  }

  // --- Private Helpers ---
  Future<int> _countOwners(int projectId) async {
    final countExp = _db.projectMembers.userId.count();
    final query = _db.selectOnly(_db.projectMembers)
      ..addColumns([countExp])
      ..where(
        _db.projectMembers.projectId.equals(projectId) &
            _db.projectMembers.role.equals(ProjectRole.owner.name),
      );

    return await query.map((row) => row.read(countExp)).getSingle() ?? 0;
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