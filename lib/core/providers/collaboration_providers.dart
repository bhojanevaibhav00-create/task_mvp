import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../data/database/database.dart' as db;
import 'package:task_mvp/core/providers/database_provider.dart';

/// =======================================================
/// 1. SHARED PROVIDERS
/// =======================================================

final allProjectsProvider = FutureProvider.autoDispose<List<db.Project>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.select(database.projects).get();
});

/// =======================================================
/// 2. MODELS & UI JOINS
/// =======================================================

class MemberWithUser {
  final db.ProjectMember member;
  final db.User user;

  MemberWithUser(this.member, this.user);
}

/// =======================================================
/// 3. PROJECT MEMBERS (FETCH LOGIC)
/// =======================================================

final projectMembersProvider = FutureProvider.family<List<MemberWithUser>, int>((ref, projectId) async {
  final database = ref.watch(databaseProvider);

  final query = database.select(database.projectMembers).join([
    innerJoin(
      database.users,
      database.users.id.equalsExp(database.projectMembers.userId),
    ),
  ]);

  query.where(database.projectMembers.projectId.equals(projectId));

  final rows = await query.get();

  return rows.map((row) => MemberWithUser(
      row.readTable(database.projectMembers),
      row.readTable(database.users),
    )).toList();
});

/// =======================================================
/// 4. STATE NOTIFIERS (MANAGEMENT & ACTIONS)
/// =======================================================

// Manages real-time UI state for member lists
class ProjectMembersNotifier extends StateNotifier<AsyncValue<List<MemberWithUser>>> {
  final db.AppDatabase database;
  final int projectId;
  final Ref ref;

  ProjectMembersNotifier(this.database, this.projectId, this.ref) : super(const AsyncValue.loading()) {
    loadMembers();
  }

  Future<void> loadMembers() async {
    try {
      final members = await ref.read(projectMembersProvider(projectId).future);
      state = AsyncValue.data(members);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Handles Actions: Add, Remove (with safety), and Assignment
class CollaborationNotifier extends StateNotifier<AsyncValue<void>> {
  final db.AppDatabase database;
  final Ref ref;

  CollaborationNotifier(this.database, this.ref) : super(const AsyncValue.data(null));

  Future<void> addMember(int projectId, int userId, String role) async {
    state = const AsyncValue.loading();
    try {
      final existing = await (database.select(database.projectMembers)
            ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId)))
          .getSingleOrNull();

      if (existing != null) throw Exception("User is already a member.");

      await database.into(database.projectMembers).insert(
        db.ProjectMembersCompanion.insert(
          projectId: projectId,
          userId: userId,
          role: role,
          joinedAt: Value(DateTime.now()),
        ),
      );

      await _logCollaborationActivity(projectId, 'Member Added', 'User $userId added as $role');
      _refresh(projectId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeMember(int projectId, int userId) async {
    state = const AsyncValue.loading();
    try {
      final members = await ref.read(projectMembersProvider(projectId).future);
      final memberToDelete = members.firstWhere((m) => m.member.userId == userId);
      final owners = members.where((m) => m.member.role.toLowerCase() == 'owner').toList();

      if (memberToDelete.member.role.toLowerCase() == 'owner' && owners.length <= 1) {
        throw Exception("Safety Error: Cannot remove the last owner.");
      }

      await (database.delete(database.projectMembers)
            ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId)))
          .go();
      
      await _logCollaborationActivity(projectId, 'Member Removed', 'User ${memberToDelete.user.name} removed');
      _refresh(projectId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Common refresh logic for UI consistency
  void _refresh(int projectId) {
    ref.invalidate(projectMembersProvider(projectId));
    ref.read(projectMembersStateProvider(projectId).notifier).loadMembers();
  }

  Future<void> _logCollaborationActivity(int projectId, String action, String description) async {
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
/// 5. FINAL PROVIDER BINDINGS
/// =======================================================

final projectMembersStateProvider = StateNotifierProvider.family<ProjectMembersNotifier, AsyncValue<List<MemberWithUser>>, int>((ref, projectId) {
  return ProjectMembersNotifier(ref.watch(databaseProvider), projectId, ref);
});

final collaborationActionProvider = StateNotifierProvider<CollaborationNotifier, AsyncValue<void>>((ref) {
  return CollaborationNotifier(ref.watch(databaseProvider), ref);
});