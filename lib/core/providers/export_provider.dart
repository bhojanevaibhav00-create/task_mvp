import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/export_repository.dart';
import 'database_provider.dart';

final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExportRepository(db);
});
