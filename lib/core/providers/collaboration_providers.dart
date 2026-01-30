import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../data/database/database.dart' as db;
import 'task_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
 // Ensure databaseProvider is accessible
import '../../../data/database/database.dart';

// ✅ Move this here to make it accessible to all screens
final allProjectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.select(db.projects).get();
});

class MemberWithUser {
  final db.ProjectMember member;
  final db.User user;
  MemberWithUser(this.member, this.user);
}

/// PROVIDER: Fetches the list of project members using an inner join with the Users table
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

/// NOTIFIER: Handles Adding/Removing members and enforcing Role Safety rules
class CollaborationNotifier extends StateNotifier<AsyncValue<void>> {
  final db.AppDatabase database;
  CollaborationNotifier(this.database) : super(const AsyncValue.data(null));

  // --- 1. Add Member logic ---
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

      // Log activity to the database
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

  // --- 2. Remove Member logic with Last-Owner Protection ---
  Future<void> removeMember(int projectId, int userId, List<MemberWithUser> allMembers) async {
    state = const AsyncValue.loading();
    try {
      // Find the specific member we want to delete
      final memberToDelete = allMembers.firstWhere((m) => m.member.userId == userId);
      
      // Filter list to find all current owners
      final owners = allMembers.where((m) => m.member.role.toLowerCase() == 'owner').toList();

      // ROLE SAFETY CHECK:
      // If the member to delete is an Owner, check if they are the ONLY owner left.
      if (memberToDelete.member.role.toLowerCase() == 'owner' && owners.length <= 1) {
        throw Exception("Safety Error: Cannot remove the last owner. Project must have at least one owner.");
      }

      // Proceed with deletion if check passes
      await (database.delete(database.projectMembers)
        ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId)))
        .go();
      
      // Log the removal activity
      await _logCollaborationActivity(
        projectId: projectId,
        action: 'Member Removed',
        details: 'User ${memberToDelete.user.name} removed from project',
      );
        
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      // Re-throw to allow the UI to catch the specific safety error message
      rethrow; 
    }
  }

  // --- 3. Private Helper: Logs collaboration events to Activity table ---
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

final collaborationActionProvider = StateNotifierProvider<CollaborationNotifier, AsyncValue<void>>((ref) {
  return CollaborationNotifier(ref.watch(databaseProvider));
});