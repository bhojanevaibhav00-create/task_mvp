import 'dart:math';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/enums.dart';

class SeedData {
  static Future<void> generate(AppDatabase db) async {
    final r = Random();

    // 1. Create Projects
    final projectIds = <int>[];

    // Active Projects
    projectIds.add(
      await db
          .into(db.projects)
          .insert(
            ProjectsCompanion.insert(
              name: 'Personal',
              description: const Value('Personal tasks and errands'),
              color: const Value(0xFF4CAF50),
              createdAt: Value(DateTime.now()),
            ),
          ),
    );

    projectIds.add(
      await db
          .into(db.projects)
          .insert(
            ProjectsCompanion.insert(
              name: 'Work',
              description: const Value('Office projects'),
              color: const Value(0xFF2196F3),
              createdAt: Value(DateTime.now()),
            ),
          ),
    );

    // High Volume Project
    final highVolumeId = await db
        .into(db.projects)
        .insert(
          ProjectsCompanion.insert(
            name: 'Migration (High Volume)',
            description: const Value('System migration tasks'),
            color: const Value(0xFFFF9800),
            createdAt: Value(DateTime.now()),
          ),
        );
    projectIds.add(highVolumeId);

    // Archived Project
    await db
        .into(db.projects)
        .insert(
          ProjectsCompanion.insert(
            name: 'Legacy System',
            isArchived: const Value(true),
            color: const Value(0xFF9E9E9E),
            createdAt: Value(
              DateTime.now().subtract(const Duration(days: 365)),
            ),
          ),
        );

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

    // 3. Create Tasks (Mixed)
    final statuses = TaskStatus.values.map((e) => e.name).toList();

    for (int i = 0; i < 50; i++) {
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

      // Assign first 30 tasks to High Volume project
      int? projectId;
      if (i < 30) {
        projectId = highVolumeId;
      } else {
        projectId = projectIds.isNotEmpty
            ? projectIds[r.nextInt(projectIds.length)]
            : null;
      }

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
              projectId: const Value(null),
              taskId: const Value(null),
            ),
          );
    }

    // 5. Create Notifications
    final notificationTypes = ['reminder', 'alert', 'system'];
    for (int i = 0; i < 5; i++) {
      await db
          .into(db.notifications)
          .insert(
            NotificationsCompanion.insert(
              type: notificationTypes[r.nextInt(notificationTypes.length)],
              title: 'Notification ${i + 1}',
              message: 'This is a sample notification generated by seed data.',
              isRead: Value(r.nextBool()),
              createdAt: Value(
                DateTime.now().subtract(Duration(hours: r.nextInt(48))),
              ),
            ),
          );
    }
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
