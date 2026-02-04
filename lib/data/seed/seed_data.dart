import 'package:drift/drift.dart';
import '../database/database.dart';

class SeedData {
  final AppDatabase db;

  SeedData(this.db);

  /// Populates the database with mock users, projects, members, and assigned tasks.
  Future<void> seed() async {
    // 0. OPTIONAL: Clear existing data to ensure a clean demo environment
    // await db.delete(db.tasks).go();
    // await db.delete(db.projects).go();

    // 1. Create Users
    final users = [
      'Alice Johnson',
      'Bob Smith',
      'Charlie Davis',
      'Diana Prince',
      'Evan Wright',
    ];

    final userIds = <String, int>{};

    for (final name in users) {
      final existing = await (db.select(db.users)..where((u) => u.name.equals(name))).getSingleOrNull();

      if (existing != null) {
        userIds[name] = existing.id;
      } else {
        final id = await db.into(db.users).insert(UsersCompanion(name: Value(name)));
        userIds[name] = id;
      }
    }

    // 2. Create Projects
    final projects = [
      {'name': 'Mobile App Redesign', 'color': 0xFF6366F1}, // Premium Indigo
      {'name': 'Backend Migration', 'color': 0xFF10B981}, // Premium Green
    ];

    final projectIds = <String, int>{};

    for (final p in projects) {
      final name = p['name'] as String;
      final color = p['color'] as int;

      final existing = await (db.select(db.projects)..where((p) => p.name.equals(name))).getSingleOrNull();

      if (existing != null) {
        projectIds[name] = existing.id;
      } else {
        final id = await db.into(db.projects).insert(
              ProjectsCompanion(
                name: Value(name),
                description: Value('Collaboration project for $name'),
                color: Value(color),
                createdAt: Value(DateTime.now()),
                updatedAt: Value(DateTime.now()),
              ),
            );
        projectIds[name] = id;
      }
    }

    // 3. Add Project Members
    final memberships = {
      'Mobile App Redesign': [
        {'user': 'Alice Johnson', 'role': 'owner'},
        {'user': 'Bob Smith', 'role': 'admin'},
        {'user': 'Charlie Davis', 'role': 'member'},
      ],
      'Backend Migration': [
        {'user': 'Alice Johnson', 'role': 'member'},
        {'user': 'Diana Prince', 'role': 'owner'},
        {'user': 'Evan Wright', 'role': 'member'},
      ],
    };

    for (final entry in memberships.entries) {
      final projectName = entry.key;
      final members = entry.value;
      final pid = projectIds[projectName];

      if (pid == null) continue;

      for (final m in members) {
        final uid = userIds[m['user']!];
        if (uid == null) continue;

        await db.into(db.projectMembers).insert(
              ProjectMembersCompanion(
                projectId: Value(pid),
                userId: Value(uid),
                role: Value(m['role']!),
                joinedAt: Value(DateTime.now()),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    }

    // 4. Create Tasks (FIXED STATUS STRINGS FOR FILTERS)
    final now = DateTime.now();
    final tasks = [
      {
        'title': 'Design System Setup',
        'project': 'Mobile App Redesign',
        'assignee': 'Alice Johnson',
        'status': 'DONE', // ✅ Standardized
        'priority': 3,
        'dueDate': now.subtract(const Duration(days: 5)),
      },
      {
        'title': 'Login Screen UI',
        'project': 'Mobile App Redesign',
        'assignee': 'Bob Smith',
        'status': 'INPROGRESS', // ✅ Standardized
        'priority': 2,
        'dueDate': now.add(const Duration(days: 2)),
      },
      {
        'title': 'API Integration',
        'project': 'Mobile App Redesign',
        'assignee': 'Bob Smith',
        'status': 'TODO', // ✅ Standardized
        'priority': 2,
        'dueDate': now, // Today
      },
      {
        'title': 'Legacy Code Cleanup',
        'project': 'Backend Migration',
        'assignee': 'Alice Johnson',
        'status': 'TODO',
        'priority': 1,
        'dueDate': now.subtract(const Duration(days: 2)), // Overdue
      },
    ];

    for (final t in tasks) {
      final pid = projectIds[t['project'] as String];
      final uid = userIds[t['assignee'] as String];
      final title = t['title'] as String;

      if (pid != null && uid != null) {
        final existing = await (db.select(db.tasks)
              ..where((tbl) => tbl.title.equals(title) & tbl.projectId.equals(pid)))
            .getSingleOrNull();

        if (existing == null) {
          await db.into(db.tasks).insert(
                TasksCompanion(
                  title: Value(title),
                  description: Value('Detailed requirements for $title'),
                  projectId: Value(pid),
                  assigneeId: Value(uid),
                  status: Value(t['status'] as String),
                  priority: Value(t['priority'] as int),
                  dueDate: Value(t['dueDate'] as DateTime?),
                  createdAt: Value(DateTime.now()),
                  updatedAt: Value(DateTime.now()),
                ),
              );
        }
      }
    }
  }
}