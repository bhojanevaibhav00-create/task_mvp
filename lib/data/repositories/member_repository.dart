import 'package:drift/drift.dart';
import '../database/database.dart';

class MemberRepository {
  final AppDatabase _db;
  MemberRepository(this._db);

  // प्रोजेक्टमध्ये नसलेले युजर्स शोधण्यासाठी
  Future<List<User>> getAvailableUsers(int projectId) async {
    final members = await (_db.select(_db.projectMembers)
          ..where((t) => t.projectId.equals(projectId)))
        .get();
    final memberIds = members.map((m) => m.userId).toList();

    return (_db.select(_db.users)
          ..where((t) => t.id.isNotIn(memberIds)))
        .get();
  }

  // नवीन मेंबर ॲड करणे
  Future<void> addMember(int projectId, int userId, String role) async {
    await _db.into(_db.projectMembers).insert(
      ProjectMembersCompanion.insert(
        projectId: projectId,
        userId: userId,
        role: role,
      ),
    );
  }
}