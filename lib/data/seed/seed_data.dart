import 'package:drift/drift.dart';
import '../database/database.dart';

class SeedData {
  final AppDatabase db;

  SeedData(this.db);

  /// Populates the database with mock users, projects, members, and assigned tasks.
  Future<void> seed() async {
    // 0. Clear existing data for a clean P0 verification environment
    await db.delete(db.tasks).go();
    await db.delete(db.projectMembers).go();
    await db.delete(db.projects).go();
    await db.delete(db.notifications).go();
    await db.delete(db.activityLogs).go();

    // 1. Create Mock Users
    final users = [
      'Alice Johnson', // Primary Owner
      'Bob Smith',    // Admin
      'Charlie Davis', // Member
      'Diana Prince',  // Project Owner 2
      'Evan Wright',   // Member
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
      {'name': 'Mobile App Redesign', 'color': 0xFF6366F1}, 
      {'name': 'Backend Migration', 'color': 0xFF10B981}, 
    ];

    final projectIds = <String, int>{};

    for (final p in projects) {
      final name = p['name'] as String;
      final color = p['color'] as int;

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

    // 3. Add Project Members (Verifying Role Safety & Multiple Roles)
    final memberships = {
      'Mobile App Redesign': [
        {'user': 'Alice Johnson', 'role': 'owner'}, // Required for safety check
        {'user': 'Bob Smith', 'role': 'admin'},
        {'user': 'Charlie Davis', 'role': 'member'},
      ],
      'Backend Migration': [
        {'user': 'Diana Prince', 'role': 'owner'},
        {'user': 'Alice Johnson', 'role': 'member'},
        {'user': 'Evan Wright', 'role': 'member'},
      ],
    };

    for (final entry in memberships.entries) {
      final pid = projectIds[entry.key];
      if (pid == null) continue;

      for (final m in entry.value) {
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

    // 4. Create Assigned Tasks (Verifying "Assigned To" Chips & Logs)
    final now = DateTime.now();
    final tasks = [
      {
        'title': 'Setup Design Tokens',
        'project': 'Mobile App Redesign',
        'assignee': 'Alice Johnson',
        'status': 'DONE',
        'priority': 3,
        'dueDate': now.subtract(const Duration(days: 1)),
      },
      {
        'title': 'Implement Auth Flow',
        'project': 'Mobile App Redesign',
        'assignee': 'Bob Smith',
        'status': 'INPROGRESS',
        'priority': 3,
        'dueDate': now.add(const Duration(days: 3)),
      },
      {
        'title': 'Database Optimization',
        'project': 'Backend Migration',
        'assignee': 'Diana Prince',
        'status': 'TODO',
        'priority': 2,
        'dueDate': now.add(const Duration(days: 2)),
      },
      {
        'title': 'Fix Navigation Overlap',
        'project': 'Mobile App Redesign',
        'assignee': 'Charlie Davis',
        'status': 'TODO',
        'priority': 1,
        'dueDate': now,
      },
    ];

    for (final t in tasks) {
      final pid = projectIds[t['project'] as String];
      final uid = userIds[t['assignee'] as String];
      final title = t['title'] as String;

      if (pid != null && uid != null) {
        final taskId = await db.into(db.tasks).insert(
              TasksCompanion(
                title: Value(title),
                description: Value('Assigned task for P0 Verification'),
                projectId: Value(pid),
                assigneeId: Value(uid),
                status: Value(t['status'] as String),
                priority: Value(t['priority'] as int),
                dueDate: Value(t['dueDate'] as DateTime?),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

        // ✅ AUTO-GENERATE ACTIVITY LOG FOR SEED DATA
        await db.into(db.activityLogs).insert(
              ActivityLogsCompanion.insert(
                action: 'assigned',
                description: Value('Task "$title" seeded with assignment to $uid'),
                taskId: Value(taskId),
                projectId: Value(pid),
                timestamp: Value(now),
              ),
            );

        // ✅ AUTO-GENERATE NOTIFICATION FOR SEED DATA (To check badge count)
        await db.into(db.notifications).insert(
              NotificationsCompanion.insert(
                type: 'assignment',
                title: 'New Assignment',
                message: 'You have been assigned to: $title',
                taskId: Value(taskId),
                projectId: Value(pid),
                createdAt: Value(now),
                isRead: const Value(false),
              ),
            );
      }
    }
  }
}