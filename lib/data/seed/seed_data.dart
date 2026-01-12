import 'dart:math';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/enums.dart';

class SeedData {
  static Future<void> generate(AppDatabase db) async {
    final r = Random();

    // 1. Create Projects (3-5)
    final projectIds = <int>[];
    final numProjects = 3 + r.nextInt(3); // 3 to 5
    for (int i = 0; i < numProjects; i++) {
      final id = await db
          .into(db.projects)
          .insert(
            ProjectsCompanion.insert(
              title: 'Project ${i + 1}: ${_getRandomProjectName(r)}',
              createdAt: DateTime.now(),
            ),
          );
      projectIds.add(id);
    }

    // 2. Create Tags
    final tagIds = <int>[];
    final tagsData = [
      {'label': 'Urgent', 'color': 0xFFFF0000},
      {'label': 'Work', 'color': 0xFF0000FF},
      {'label': 'Home', 'color': 0xFF00FF00},
      {'label': 'Feature', 'color': 0xFF800080},
      {'label': 'Bug', 'color': 0xFFFFA500},
    ];

    for (var tag in tagsData) {
      final id = await db
          .into(db.tags)
          .insert(
            TagsCompanion.insert(
              label: tag['label'] as String,
              colorHex: tag['color'] as int,
            ),
          );
      tagIds.add(id);
    }

    // 3. Create Tasks (25-40)
    final numTasks = 25 + r.nextInt(16); // 25 to 40
    final statuses = TaskStatus.values.map((e) => e.name).toList();

    for (int i = 0; i < numTasks; i++) {
      final status = statuses[r.nextInt(statuses.length)];
      final priority = 1 + r.nextInt(3); // 1, 2, 3

      // Date logic
      DateTime? dueDate;
      final dateType = r.nextInt(
        4,
      ); // 0: today, 1: overdue, 2: upcoming, 3: null
      final now = DateTime.now();

      switch (dateType) {
        case 0: // Today
          dueDate = now;
          break;
        case 1: // Overdue
          dueDate = now.subtract(Duration(days: 1 + r.nextInt(10)));
          break;
        case 2: // Upcoming
          dueDate = now.add(Duration(days: 1 + r.nextInt(14)));
          break;
        case 3: // No date
          dueDate = null;
          break;
      }

      final projectId = projectIds.isNotEmpty
          ? projectIds[r.nextInt(projectIds.length)]
          : null;
      final tagId = tagIds.isNotEmpty ? tagIds[r.nextInt(tagIds.length)] : null;

      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              title: 'Task ${i + 1}: ${_getRandomTaskTitle(r)}',
              description: Value(
                'Description for task ${i + 1}. ${_getRandomDescription(r)}',
              ),
              status: Value(status),
              priority: Value(priority),
              dueDate: Value(dueDate),
              projectId: Value(projectId),
              tagId: Value(tagId),
              createdAt: Value(now.subtract(Duration(days: r.nextInt(30)))),
            ),
          );
    }

    // 4. Create Activity Logs (Sample Data)
    final actions = [
      'created',
      'edited',
      'status_changed',
      'completed',
      'moved',
    ];
    for (int i = 0; i < 15; i++) {
      final action = actions[r.nextInt(actions.length)];
      await db
          .into(db.activityLogs)
          .insert(
            ActivityLogsCompanion.insert(
              action: action,
              description: Value('System generated activity ${i + 1}'),
              timestamp: Value(
                DateTime.now().subtract(Duration(hours: r.nextInt(48))),
              ),
            ),
          );
    }
  }

  static String _getRandomProjectName(Random r) {
    const names = [
      'Website Redesign',
      'Mobile App',
      'Marketing Campaign',
      'Q4 Goals',
      'Maintenance',
    ];
    return names[r.nextInt(names.length)];
  }

  static String _getRandomTaskTitle(Random r) {
    const verbs = [
      'Fix',
      'Update',
      'Create',
      'Review',
      'Delete',
      'Refactor',
      'Test',
    ];
    const nouns = [
      'Login',
      'Dashboard',
      'Profile',
      'Settings',
      'Database',
      'API',
      'UI',
    ];
    return '${verbs[r.nextInt(verbs.length)]} ${nouns[r.nextInt(nouns.length)]}';
  }

  static String _getRandomDescription(Random r) {
    const desc = [
      'Needs urgent attention.',
      'Discuss with the team first.',
      'Check the requirements doc.',
      'Optimization required.',
      'Customer reported issue.',
    ];
    return desc[r.nextInt(desc.length)];
  }
}
