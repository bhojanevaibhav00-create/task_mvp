import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/analytics_models.dart';
import '../../data/repositories/analytics_repository.dart';
import 'database_provider.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AnalyticsRepository(db);
});

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((
  ref,
) {
  return ref.watch(analyticsRepositoryProvider).getDashboardStats();
});

final memberStatsProvider = FutureProvider.family
    .autoDispose<List<MemberStats>, int?>((ref, projectId) {
      return ref
          .watch(analyticsRepositoryProvider)
          .getMemberStats(projectId: projectId);
    });
