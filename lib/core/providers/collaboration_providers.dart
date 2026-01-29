import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
// Alias 'db' is mandatory here to distinguish from Drift's internal 'Table'
import '../../data/database/database.dart' as db;
import '../../../core/providers/task_providers.dart';

class MemberWithUser {
  final db.ProjectMember member;
  final db.User user;
  MemberWithUser(this.member, this.user);
}

final projectMembersProvider = FutureProvider.family<List<MemberWithUser>, int>((ref, projectId) async {
  final database = ref.watch(databaseProvider);
  
  // Create the select statement on the main table first
  final select = database.select(database.projectMembers);

  // Use the .join function directly on the select statement
  final query = select.join([
    innerJoin(
      database.users, 
      database.users.id.equalsExp(database.projectMembers.userId),
    ),
  ]);

  // Apply filter
  query.where(database.projectMembers.projectId.equals(projectId));

  final rows = await query.get();
  
  return rows.map((row) {
    return MemberWithUser(
      row.readTable(database.projectMembers),
      row.readTable(database.users),
    );
  }).toList();
});

class CollaborationNotifier extends StateNotifier<AsyncValue<void>> {
  final db.AppDatabase database;
  CollaborationNotifier(this.database) : super(const AsyncValue.data(null));

  Future<void> removeMember(int projectId, int userId, List<MemberWithUser> allMembers) async {
    try {
      final owners = allMembers.where((m) => m.member.role.toLowerCase() == 'owner').toList();
      final memberToDelete = allMembers.firstWhere((m) => m.member.userId == userId);

      if (memberToDelete.member.role.toLowerCase() == 'owner' && owners.length <= 1) {
        throw Exception("Cannot remove the last owner of the project.");
      }

      // Use the logical AND (&) for the composite key deletion
      await (database.delete(database.projectMembers)
        ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId)))
        .go();
        
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final collaborationActionProvider = StateNotifierProvider<CollaborationNotifier, AsyncValue<void>>((ref) {
  return CollaborationNotifier(ref.watch(databaseProvider));
});