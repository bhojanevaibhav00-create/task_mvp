import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_mvp/core/providers/database_provider.dart';
import '../../data/database/database.dart';
import '../../data/repositories/auth_repository.dart';
import 'task_providers.dart'; // To access databaseProvider

/// Provides the Repository to the UI
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AuthRepository(db);
});

/// Manages the Current User State (Null = Logged Out)
final authStateProvider = StateProvider<User?>((ref) => null);

/// Boolean check for easy UI switching
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider) != null;
});