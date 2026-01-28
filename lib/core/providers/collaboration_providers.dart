import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
// Alias 'db' is mandatory here
import '../../data/database/database.dart' as db;
import 'task_providers.dart';

class MemberWithUser {
  final db.ProjectMember member;
  final db.User user;
  MemberWithUser(this.member, this.user);
}

/// 🚀 PROVIDER: प्रोजेक्ट मेंबर्सची यादी 'innerJoin' वापरून मिळवण्यासाठी
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

/// 🚀 NOTIFIER: मेंबर ॲड/रिमूव्ह करणे आणि ॲक्टिव्हिटी लॉग करणे
class CollaborationNotifier extends StateNotifier<AsyncValue<void>> {
  final db.AppDatabase database;
  CollaborationNotifier(this.database) : super(const AsyncValue.data(null));

  // --- १. मेंबर ॲड करणे (Add Member Flow) ---
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

      // ✅ Activity Log: नवीन मेंबर ॲड केल्याची नोंद करणे
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

  // --- २. मेंबर रिमूव्ह करणे (Remove Member Flow) ---
  Future<void> removeMember(int projectId, int userId, List<MemberWithUser> allMembers) async {
    try {
      final owners = allMembers.where((m) => m.member.role.toLowerCase() == 'owner').toList();
      final memberToDelete = allMembers.firstWhere((m) => m.member.userId == userId);

      // 🔐 Last-owner protection logic
      if (memberToDelete.member.role.toLowerCase() == 'owner' && owners.length <= 1) {
        throw Exception("At least 1 Owner required");
      }

      await (database.delete(database.projectMembers)
        ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId)))
        .go();
      
      
      await _logCollaborationActivity(
        projectId: projectId,
        action: 'Member Removed',
        details: 'User ID $userId removed from project',
      );
        
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // --- ३. खाजगी पद्धत: Activity + Notifications integration ---
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