import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import 'task_providers.dart';
import 'package:task_mvp/core/providers/database_provider.dart';
final allProjectsProvider =
FutureProvider.autoDispose<List<Project>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.select(db.projects).get();
});