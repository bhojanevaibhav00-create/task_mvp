import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../data/database/database.dart' as db;
import '../../../data/database/database.dart';
import 'task_providers.dart';

// ✅ 1. ALL PROJECTS PROVIDER
final allProjectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final database = ref.watch(databaseProvider);
  final results = await database.select(database.projects).get();
  return results;
});

// ✅ 2. DATA MODEL FOR UI JOIN
class MemberWithUser {
  final db.ProjectMember member;
  final db.User user;
  MemberWithUser(this.member, this.user);
}

// ✅ 3. PROJECT MEMBERS PROVIDER (Core Stream)
final projectMembersProvider = FutureProvider.family<List<MemberWithUser>, int>((ref, projectId) async {
  final database = ref.watch(databaseProvider);
  
  final select = database.select(database.projectMembers);

  final query = select.join([
    innerJoin(
      database.users, 
      database.users.id.equalsExp(database.projectMembers.userId),
    ),
  ]);

  query.where(database.projectMembers.projectId.equals(projectId));

  final rows = await query.get();
  
  return rows.map((row) {
    return MemberWithUser(
      row.readTable(database.projectMembers),
      row.readTable(database.users),
    );
  }).toList();
});

// ✅ 4. PROJECT MEMBERS NOTIFIER (Manages Member List State)
// This is used for real-time UI updates when members are modified
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

final projectMembersStateProvider = StateNotifierProvider.family<ProjectMembersNotifier, AsyncValue<List<MemberWithUser>>, int>((ref, projectId) {
  return ProjectMembersNotifier(ref.watch(databaseProvider), projectId, ref);
});

// ✅ 5. COLLABORATION NOTIFIER (Handles Actions: Add/Remove/Role Safety)
class CollaborationNotifier extends StateNotifier<AsyncValue<void>> {
  final db.AppDatabase database;
  final Ref ref;

  CollaborationNotifier(this.database, this.ref) : super(const AsyncValue.data(null));

  // --- Add Member logic ---
  Future<void> addMember(int projectId, int userId, String role) async {
    state = const AsyncValue.loading();
    try {
      // Duplicate prevention check
      final existing = await (database.select(database.projectMembers)
        ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId)))
        .getSingleOrNull();

      if (existing != null) {
        throw Exception("This user is already a member of this project.");
      }

      await database.into(database.projectMembers).insert(
        db.ProjectMembersCompanion.insert(
          projectId: projectId,
          userId: userId,
          role: role,
          joinedAt: Value(DateTime.now()),
        ),
      );

      await _logCollaborationActivity(
        projectId: projectId,
        action: 'Member Added',
        details: 'User ID $userId added as $role',
      );

      // Refresh the UI state
      ref.invalidate(projectMembersProvider(projectId));
      ref.read(projectMembersStateProvider(projectId).notifier).loadMembers();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // --- Remove Member logic with Last-Owner Protection ---
  Future<void> removeMember(int projectId, int userId, List<MemberWithUser> allMembers) async {
    state = const AsyncValue.loading();
    try {
      final members = await ref.read(projectMembersProvider(projectId).future);
      final memberToDelete = members.firstWhere((m) => m.member.userId == userId);
      final owners = members.where((m) => m.member.role.toLowerCase() == 'owner').toList();

      // ROLE SAFETY CHECK:
      if (memberToDelete.member.role.toLowerCase() == 'owner' && owners.length <= 1) {
        throw Exception("Safety Error: Cannot remove the last owner. Project must have at least one owner.");
      }

      await (database.delete(database.projectMembers)
        ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId)))
        .go();
      
      await _logCollaborationActivity(
        projectId: projectId,
        action: 'Member Removed',
        details: 'User ${memberToDelete.user.name} removed from project',
      );

      // Refresh the UI state
      ref.invalidate(projectMembersProvider(projectId));
      ref.read(projectMembersStateProvider(projectId).notifier).loadMembers();
        
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; 
    }
  }

  Future<void> _logCollaborationActivity({
    required int projectId,
    required String action,
    required String details,
  }) async {
    await database.into(database.activityLogs).insert(
      db.ActivityLogsCompanion.insert(
        action: action,
        description: Value(details),
        projectId: Value(projectId),
        timestamp: Value(DateTime.now()),
      ),
    );
  }
}

// ✅ 6. ACTION PROVIDER EXPOSURE
final collaborationActionProvider = StateNotifierProvider<CollaborationNotifier, AsyncValue<void>>((ref) {
  return CollaborationNotifier(ref.watch(databaseProvider), ref);
});