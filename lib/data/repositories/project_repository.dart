import 'package:drift/drift.dart';
import '../database/database.dart';

/// Data Transfer Object for Project with computed statistics
class ProjectStatistics {
  final Project project;
  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final int upcomingTasks;
  final int todayTasks;

  double get progress => totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

  ProjectStatistics({
    required this.project,
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.upcomingTasks,
    required this.todayTasks,
  });
}

class ProjectRepository {
  final AppDatabase _db;

  ProjectRepository(this._db);

  // --- CRUD Operations ---

  /// Creates a new project.
  Future<int> createProject(ProjectsCompanion project) {
    return _db.into(_db.projects).insert(project);
  }

  /// Updates an existing project.
  /// Automatically updates the [updatedAt] field.
  Future<bool> updateProject(Project project) {
    return _db
        .update(_db.projects)
        .replace(project.copyWith(updatedAt: Value(DateTime.now())));
  }

  /// Archives a project by setting [isArchived] to true.
  Future<void> archiveProject(int id) {
    return (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
      ProjectsCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Fetches a single project by ID.
  Future<Project?> getProjectById(int id) {
    return (_db.select(
      _db.projects,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Lists projects. By default, excludes archived projects.
  Future<List<Project>> listProjects({bool includeArchived = false}) {
    return (_db.select(_db.projects)
          ..where(
            (t) => includeArchived
                ? const Constant(true)
                : t.isArchived.equals(false),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  // --- Computed Queries ---

  /// Watches projects with computed statistics (progress, counts).
  /// Useful for dashboard overview cards.
  Stream<List<ProjectStatistics>> watchProjectStatistics({
    bool includeArchived = false,
  }) {
    final projectsQuery = _db.select(_db.projects);
    if (!includeArchived) {
      projectsQuery.where((t) => t.isArchived.equals(false));
    }

    final query = projectsQuery.join([
      leftOuterJoin(_db.tasks, _db.tasks.projectId.equalsExp(_db.projects.id)),
    ]);

    return query.watch().map((rows) {
      // Group tasks by project
      final grouped = <Project, List<Task>>{};

      for (final row in rows) {
        final project = row.readTable(_db.projects);
        final task = row.readTableOrNull(_db.tasks);

        if (!grouped.containsKey(project)) {
          grouped[project] = [];
        }
        if (task != null) {
          grouped[project]!.add(task);
        }
      }

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      return grouped.entries.map((entry) {
        final project = entry.key;
        final tasks = entry.value;

        final total = tasks.length;
        final done = tasks.where((t) => t.status == 'done').length;

        // Filter for active tasks (not done) for time-based stats
        final activeTasks = tasks.where((t) => t.status != 'done');

        int overdueCount = 0;
        int todayCount = 0;
        int upcomingCount = 0;

        for (final t in activeTasks) {
          if (t.dueDate == null) continue;

          if (t.dueDate!.isBefore(now)) {
            overdueCount++;
          } else if (!t.dueDate!.isBefore(todayStart) &&
              t.dueDate!.isBefore(todayEnd)) {
            // Check if date is today (inclusive of start, exclusive of end)
            todayCount++;
          } else if (t.dueDate!.isAfter(todayEnd)) {
            upcomingCount++;
          }
        }

        return ProjectStatistics(
          project: project,
          totalTasks: total,
          completedTasks: done,
          overdueTasks: overdueCount,
          todayTasks: todayCount,
          upcomingTasks: upcomingCount,
        );
      }).toList();
    });
  }
}
