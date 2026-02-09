import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../../data/database/database.dart' as db;
import '../../data/database/database.dart';
import 'task_providers.dart';
import 'package:task_mvp/core/providers/database_provider.dart';
/// =======================================================
/// SHARED PROVIDER: All Projects
/// =======================================================
final allProjectsProvider =
FutureProvider.autoDispose<List<Project>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.select(database.projects).get();
});

/// =======================================================
/// MODEL: Member + User (UI friendly)
/// =======================================================
class MemberWithUser {
  final db.ProjectMember member;
  final db.User user;

  MemberWithUser(this.member, this.user);
}

/// =======================================================
/// PROVIDER: Fetch Project Members (JOIN users + members)
/// =======================================================
final projectMembersProvider =
FutureProvider.family<List<MemberWithUser>, int>((ref, projectId) async {
  final database = ref.watch(databaseProvider);

  final query = database.select(database.projectMembers).join([
    innerJoin(
      database.users,
      database.users.id.equalsExp(database.projectMembers.userId),
    ),
  ]);

  query.where(database.projectMembers.projectId.equals(projectId));

  final rows = await query.get();

  return rows
      .map(
        (row) => MemberWithUser(
      row.readTable(database.projectMembers),
      row.readTable(database.users),
    ),
  )
      .toList();
});

/// =======================================================
/// NOTIFIER: Collaboration + Assignment Logic (Sprint 8 P0)
/// =======================================================
class CollaborationNotifier extends StateNotifier<AsyncValue<void>> {
  final db.AppDatabase database;

  CollaborationNotifier(this.database)
      : super(const AsyncValue.data(null));

  /// -------------------------------------------------------
  /// 1️⃣ ADD MEMBER
  /// -------------------------------------------------------
  Future<void> addMember({
    required int projectId,
    required int userId,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    try {
      await database.into(database.projectMembers).insert(
        db.ProjectMembersCompanion.insert(
          projectId: projectId,
          userId: userId,
          role: role,
        ),
      );

      await _logActivity(
        projectId: projectId,
        action: 'Member Added',
        description: 'User $userId added as $role',
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// -------------------------------------------------------
  /// 2️⃣ REMOVE MEMBER (LAST OWNER SAFETY)
  /// -------------------------------------------------------
  Future<void> removeMember({
    required int projectId,
    required int userId,
    required List<MemberWithUser> allMembers,
  }) async {
    state = const AsyncValue.loading();
    try {
      final member =
      allMembers.firstWhere((m) => m.member.userId == userId);

      final owners = allMembers
          .where((m) => m.member.role.toLowerCase() == 'owner')
          .toList();

      if (member.member.role.toLowerCase() == 'owner' &&
          owners.length <= 1) {
        throw Exception(
            'Cannot remove the last owner of the project');
      }

      await (database.delete(database.projectMembers)
        ..where(
              (t) =>
          t.projectId.equals(projectId) &
          t.userId.equals(userId),
        ))
          .go();

      await _logActivity(
        projectId: projectId,
        action: 'Member Removed',
        description: 'User ${member.user.name} removed',
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// -------------------------------------------------------
  /// 3️⃣ ASSIGN TASK TO MEMBER
  /// -------------------------------------------------------
  Future<void> assignTask({
    required int taskId,
    required int userId,
    required int projectId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final task = await (database.select(database.tasks)
        ..where((t) => t.id.equals(taskId)))
          .getSingle();

      await database.update(database.tasks).replace(
        task.copyWith(
          assigneeId: Value(userId),
          projectId: Value(projectId),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await _logActivity(
        projectId: projectId,
        action: 'Task Assigned',
        description: 'Task $taskId assigned to user $userId',
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// -------------------------------------------------------
  /// 4️⃣ UNASSIGN TASK
  /// -------------------------------------------------------
  Future<void> unassignTask({
    required int taskId,
    required int projectId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final task = await (database.select(database.tasks)
        ..where((t) => t.id.equals(taskId)))
          .getSingle();

      await database.update(database.tasks).replace(
        task.copyWith(
          assigneeId: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await _logActivity(
        projectId: projectId,
        action: 'Task Unassigned',
        description: 'Task $taskId unassigned',
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// -------------------------------------------------------
  /// INTERNAL: ACTIVITY LOGGING
  /// -------------------------------------------------------
  Future<void> _logActivity({
    required int projectId,
    required String action,
    required String description,
  }) async {
    await database.into(database.activityLogs).insert(
      db.ActivityLogsCompanion.insert(
        action: action,
        description: Value(description),
        projectId: Value(projectId),
        timestamp: Value(DateTime.now()),
      ),
    );
  }
}

/// =======================================================
/// PROVIDER BINDING
/// =======================================================
final collaborationActionProvider =
StateNotifierProvider<CollaborationNotifier, AsyncValue<void>>(
      (ref) => CollaborationNotifier(ref.watch(databaseProvider)),
);
