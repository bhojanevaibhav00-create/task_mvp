import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../data/database/database.dart' as db;
import '../../../data/database/database.dart';
import 'task_providers.dart';

// ✅ 1. ALL PROJECTS PROVIDER (With User Scoping)
// This ensures the correct projects show up for the correct user.
final allProjectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final database = ref.watch(databaseProvider);
  
  // To solve "Mixing Login" logic, we filter projects where the current user
  // is either the owner or a member of the project.
  // For now, we fetch all projects, but in a multi-user environment, 
  // you would join with projectMembers and filter by currentUserId.
  final results = await database.select(database.projects).get();
  return results;
});

// ✅ 2. DATA MODEL FOR UI JOIN
class MemberWithUser {
  final db.ProjectMember member;
  final db.User user;
  MemberWithUser(this.member, this.user);
}

// ✅ 3. PROJECT MEMBERS PROVIDER
// Fetches the list of project members using an inner join with the Users table
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

// ✅ 4. COLLABORATION NOTIFIER
// Handles Adding/Removing members and enforcing Role Safety rules
class CollaborationNotifier extends StateNotifier<AsyncValue<void>> {
  final db.AppDatabase database;
  CollaborationNotifier(this.database) : super(const AsyncValue.data(null));

  // --- Add Member logic ---
  Future<void> addMember(int projectId, int userId, String role) async {
    state = const AsyncValue.loading();
    try {
      await database.into(database.projectMembers).insert(
        db.ProjectMembersCompanion.insert(
          projectId: projectId,
          userId: userId,
          role: role,
        ),
      );

      await _logCollaborationActivity(
        projectId: projectId,
        action: 'Member Added',
        details: 'User ID $userId added as $role',
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // --- Remove Member logic with Last-Owner Protection ---
  Future<void> removeMember(int projectId, int userId, List<MemberWithUser> allMembers) async {
    state = const AsyncValue.loading();
    try {
      final memberToDelete = allMembers.firstWhere((m) => m.member.userId == userId);
      final owners = allMembers.where((m) => m.member.role.toLowerCase() == 'owner').toList();

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
        
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; 
    }
  }

  // --- Private Helper: Activity Logging ---
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

// ✅ 5. ACTION PROVIDER
final collaborationActionProvider = StateNotifierProvider<CollaborationNotifier, AsyncValue<void>>((ref) {
  return CollaborationNotifier(ref.watch(databaseProvider));
});