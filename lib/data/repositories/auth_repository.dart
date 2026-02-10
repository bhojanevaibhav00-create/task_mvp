import 'package:drift/drift.dart';
import '../database/database.dart';

class AuthRepository {
  final AppDatabase _db;

  AuthRepository(this._db);

  // ✅ REGISTER
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {

    final existing = await (_db.select(_db.users)
          ..where((u) => u.email.equals(email)))
        .getSingleOrNull();

    if (existing != null) {
      throw Exception("Email already registered.");
    }

    final id = await _db.into(_db.users).insert(
      UsersCompanion.insert(
        name: name,
        email: email,        // ✅ DIRECT
        password: password,  // ✅ DIRECT
      ),
    );

    return await (_db.select(_db.users)
          ..where((u) => u.id.equals(id)))
        .getSingle();
  }

  // ✅ LOGIN
  Future<User> login(String email, String password) async {

    final user = await (_db.select(_db.users)
          ..where((u) => u.email.equals(email)))
        .getSingleOrNull();

    if (user == null) {
      throw Exception("Account not found.");
    }

    if (user.password != password) {
      throw Exception("Incorrect password.");
    }

    return user;
  }
}
