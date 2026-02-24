import 'package:drift/drift.dart';
import '../database/database.dart';

class UserRepository {
  final AppDatabase _db;
  UserRepository(this._db);

  // For a single-user app, we assume user ID is 1
  Future<User?> getUser() async {
    return await (_db.select(_db.users)..where((u) => u.id.equals(1))).getSingleOrNull();
  }

  Future<void> updatePassword(String newPassword) async {
    await (_db.update(_db.users)..where((u) => u.id.equals(1))).write(
      UsersCompanion(password: Value(newPassword)),
    );
  }
}