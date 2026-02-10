import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_mvp/data/database/database.dart';

/// ✅ GLOBAL DATABASE PROVIDER
/// Use this everywhere instead of creating AppDatabase again and again
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();

  // Close DB when app/provider is disposed
  ref.onDispose(() {
    db.close();
  });

  return db;
});