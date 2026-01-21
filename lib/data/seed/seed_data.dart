import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/enums.dart';

class SeedData {
  static Future<void> generate(AppDatabase db) async {
    // 1. Create Users (Mock Members)
    final userNames = ['Alice', 'Bob', 'Charlie', 'Diana'];
    final userIds = <int>[];

    for (final name in userNames) {
      final id = await db
          .into(db.users)
          .insert(UsersCompanion.insert(name: name));
      userIds.add(id);
    }

    // 2. Create Projects
    final p1 = await db
        .into(db.projects)
        .insert(
          ProjectsCompanion.insert(
            name: 'Website Redesign',
            description: Value('Overhaul of the corporate website'),
            color: Value(0xFF4CAF50), // Green
          ),
        );

    final p2 = await db
        .into(db.projects)
        .insert(
          ProjectsCompanion.insert(
            name: 'Mobile App MVP',
            description: Value('Flutter based task manager'),
            color: Value(0xFF2196F3), // Blue
          ),
        );

    // 3. Add Members to Projects
    // Website Redesign Team
    if (userIds.length >= 2) {
      await db
          .into(db.projectMembers)
          .insert(
            ProjectMembersCompanion.insert(
              projectId: p1,
              userId: userIds[0], // Alice
              role: 'admin',
            ),
          );
      await db
          .into(db.projectMembers)
          .insert(
            ProjectMembersCompanion.insert(
              projectId: p1,
              userId: userIds[1], // Bob
              role: 'member',
            ),
          );
    }

    // Mobile App Team
    if (userIds.length >= 4) {
      await db
          .into(db.projectMembers)
          .insert(
            ProjectMembersCompanion.insert(
              projectId: p2,
              userId: userIds[1], // Bob
              role: 'lead',
            ),
          );
      await db
          .into(db.projectMembers)
          .insert(
            ProjectMembersCompanion.insert(
              projectId: p2,
              userId: userIds[2], // Charlie
              role: 'dev',
            ),
          );
      await db
          .into(db.projectMembers)
          .insert(
            ProjectMembersCompanion.insert(
              projectId: p2,
              userId: userIds[3], // Diana
              role: 'qa',
            ),
          );
    }

    // 4. Create Tasks with Assignments
    final now = DateTime.now();

    // Tasks for Website Redesign
    if (userIds.isNotEmpty) {
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              title: 'Design Home Page',
              projectId: Value(p1),
              status: Value(TaskStatus.inProgress.dbValue),
              priority: Value(3),
              assigneeId: Value(userIds[0]), // Alice
              dueDate: Value(now.add(const Duration(days: 2))),
            ),
          );
    }

    if (userIds.length > 1) {
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              title: 'Implement CSS Grid',
              projectId: Value(p1),
              status: Value(TaskStatus.todo.dbValue),
              priority: Value(2),
              assigneeId: Value(userIds[1]), // Bob
              dueDate: Value(now.add(const Duration(days: 5))),
            ),
          );
    }

    // Tasks for Mobile App
    if (userIds.length > 2) {
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              title: 'Setup Drift Database',
              projectId: Value(p2),
              status: Value(TaskStatus.done.dbValue),
              priority: Value(3),
              assigneeId: Value(userIds[2]), // Charlie
              completedAt: Value(now.subtract(const Duration(hours: 4))),
            ),
          );
    }

    if (userIds.length > 3) {
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              title: 'Write Unit Tests',
              projectId: Value(p2),
              status: Value(TaskStatus.review.dbValue),
              priority: Value(2),
              assigneeId: Value(userIds[3]), // Diana
              dueDate: Value(now.add(const Duration(days: 1))),
            ),
          );
    }

    // Unassigned Task
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            title: 'Update Documentation',
            projectId: Value(p2),
            status: Value(TaskStatus.todo.dbValue),
            priority: Value(1),
          ),
        );
  }
}
