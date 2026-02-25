import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lead_model/lead_model.dart';
import 'database_provider.dart';

final leadsProvider = StreamProvider<List<LeadModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .select(db.leads)
      .watch()
      .map((rows) => rows.map(LeadModel.fromDrift).toList());
});
