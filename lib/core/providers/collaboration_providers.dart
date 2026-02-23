import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../data/database/database.dart' as db;
import 'database_provider.dart';

/// =======================================================
/// 1️⃣ ALL PROJECTS PROVIDER
/// =======================================================

final allProjectsProvider =
    FutureProvider.autoDispose<List<db.Project>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.select(database.projects).get();
});

/// =======================================================
/// 2️⃣ MODEL FOR JOINED MEMBER + USER
/// =======================================================

class MemberWithUser {
  final db.ProjectMember member;
  final db.User user;

  MemberWithUser(this.member, this.user);
}

/// =======================================================
/// 3️⃣ FETCH PROJECT MEMBERS (JOIN USERS TABLE)
/// =======================================================

final projectMembersProvider =
    FutureProvider.family<List<MemberWithUser>, int>(
        (ref, projectId) async {
  final database = ref.watch(databaseProvider);

  final query =
      database.select(database.projectMembers).join([
    innerJoin(
      database.users,
      database.users.id.equalsExp(
        database.projectMembers.userId,
      ),
    ),
  ]);

  query.where(
    database.projectMembers.projectId.equals(projectId),
  );

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
/// 4️⃣ STATE NOTIFIER FOR MEMBER ACTIONS
/// =======================================================

class CollaborationNotifier
    extends StateNotifier<AsyncValue<void>> {
  final db.AppDatabase database;
  final Ref ref;

  CollaborationNotifier(this.database, this.ref)
      : super(const AsyncValue.data(null));

  // =====================================================
  // ADD MEMBER
  // =====================================================

  Future<void> addMember({
    required int projectId,
    required int userId,
    required String role,
  }) async {
    state = const AsyncValue.loading();

    try {
      // 🔹 Check duplicate
      final existing =
          await (database.select(database.projectMembers)
                ..where((t) =>
                    t.projectId.equals(projectId) &
                    t.userId.equals(userId)))
              .getSingleOrNull();

      if (existing != null) {
        throw Exception("User is already a member.");
      }

      // 🔹 Insert
      await database.into(database.projectMembers).insert(
            db.ProjectMembersCompanion.insert(
              projectId: projectId,
              userId: userId,
              role: role,
              joinedAt: Value(DateTime.now()),
            ),
          );

      await _logActivity(
        projectId,
        "Member Added",
        "User $userId added as $role",
      );

      ref.invalidate(projectMembersProvider(projectId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // =====================================================
  // REMOVE MEMBER (WITH OWNER SAFETY)
  // =====================================================

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
          .where(
              (m) => m.member.role.toLowerCase() == 'owner')
          .toList();

      // 🔴 Prevent deleting last owner
      if (member.member.role.toLowerCase() == 'owner' &&
          owners.length <= 1) {
        throw Exception(
            "Cannot remove the last owner of the project.");
      }

      await (database.delete(database.projectMembers)
            ..where((t) =>
                t.projectId.equals(projectId) &
                t.userId.equals(userId)))
          .go();

      await _logActivity(
        projectId,
        "Member Removed",
        "User ${member.user.name} removed",
      );

      ref.invalidate(projectMembersProvider(projectId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // =====================================================
  // LOG ACTIVITY
  // =====================================================

  Future<void> _logActivity(
      int projectId, String action, String description) async {
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
/// 5️⃣ PROVIDER BINDING
/// =======================================================

final collaborationActionProvider =
    StateNotifierProvider<CollaborationNotifier,
        AsyncValue<void>>((ref) {
  return CollaborationNotifier(
    ref.watch(databaseProvider),
    ref,
  );
});
