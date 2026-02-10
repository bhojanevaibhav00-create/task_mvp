import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/analytics_models.dart';

class AnalyticsRepository {
  final AppDatabase _db;

  AnalyticsRepository(this._db);

  /// Fetches high-level dashboard metrics
  Future<DashboardStats> getDashboardStats() async {
    final now = DateTime.now();
    // Calculate start of the current week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    // 1. Overdue Count: Due date passed AND status is NOT 'done'
    final overdueQuery = _db.selectOnly(_db.tasks)
      ..addColumns([_db.tasks.id.count()])
      ..where(
        _db.tasks.dueDate.isSmallerThanValue(now) &
            _db.tasks.status.isNotValue('done'),
      );
    final overdue =
        await overdueQuery
            .map((row) => row.read(_db.tasks.id.count()))
            .getSingle() ??
        0;

    // 2. Completion Rate: (Completed / Total) * 100
    final totalQuery = _db.selectOnly(_db.tasks)
      ..addColumns([_db.tasks.id.count()]);
    final total =
        await totalQuery
            .map((row) => row.read(_db.tasks.id.count()))
            .getSingle() ??
        0;

    final completedQuery = _db.selectOnly(_db.tasks)
      ..addColumns([_db.tasks.id.count()])
      ..where(_db.tasks.status.equals('done'));
    final completed =
        await completedQuery
            .map((row) => row.read(_db.tasks.id.count()))
            .getSingle() ??
        0;

    // 3. Weekly Stats (Created vs Completed)
    final createdWeekQuery = _db.selectOnly(_db.tasks)
      ..addColumns([_db.tasks.id.count()])
      ..where(_db.tasks.createdAt.isBiggerOrEqualValue(startOfDay));
    final createdWeek =
        await createdWeekQuery
            .map((row) => row.read(_db.tasks.id.count()))
            .getSingle() ??
        0;

    final completedWeekQuery = _db.selectOnly(_db.tasks)
      ..addColumns([_db.tasks.id.count()])
      ..where(
        _db.tasks.completedAt.isBiggerOrEqualValue(startOfDay) &
            _db.tasks.status.equals('done'),
      );
    final completedWeek =
        await completedWeekQuery
            .map((row) => row.read(_db.tasks.id.count()))
            .getSingle() ??
        0;

    return DashboardStats(
      overdueCount: overdue,
      completionRate: total == 0 ? 0.0 : (completed / total),
      createdThisWeek: createdWeek,
      completedThisWeek: completedWeek,
    );
  }

  /// Fetches member performance, optionally filtered by project
  Future<List<MemberStats>> getMemberStats({int? projectId}) async {
    // We use custom SQL here for efficient aggregation across joined tables
    final whereClause = projectId != null ? 'AND t.project_id = ?' : '';
    final variables = <Variable<Object>>[
      if (projectId != null) Variable.withInt(projectId),
    ];

    final query =
        '''
      SELECT 
        u.name,
        COUNT(t.id) as assigned,
        SUM(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END) as completed
      FROM users u
      JOIN tasks t ON t.assignee_id = u.id
      WHERE 1=1 $whereClause
      GROUP BY u.id
      ORDER BY completed DESC
    ''';

    final result = await _db.customSelect(query, variables: variables).get();

    return result.map((row) {
      return MemberStats(
        userName: row.read<String>('name'),
        assignedTasks: row.read<int>('assigned'),
        // SQLite SUM can return null if no matches, though COUNT ensures rows exist here
        completedTasks: row.read<int?>('completed') ?? 0,
      );
    }).toList();
  }
}
