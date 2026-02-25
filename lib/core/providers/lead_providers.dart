import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import 'database_provider.dart';

final leadsProvider = StreamProvider<List<Lead>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.leads).watch();
});