import 'package:drift/drift.dart';
import '../database/app_database.dart';

Future<void> seedDatabase(AppDatabase db) async {
  final existing = await db.select(db.tasks).get();
  if (existing.isNotEmpty) return;

  // 1. Seed Users
  await db.batch((batch) => batch.insertAll(db.users, [
    UsersCompanion.insert(id: 'u1', name: 'Alice Admin', email: 'alice@example.com'),
    UsersCompanion.insert(id: 'u2', name: 'Bob Builder', email: 'bob@example.com'),
  ]));

  // 2. Seed Projects
  await db.batch((batch) => batch.insertAll(db.projects, [
    ProjectsCompanion.insert(id: 'p1', name: 'Mobile App MVP', color: '#FF5733', ownerId: 'u1'),
    ProjectsCompanion.insert(id: 'p2', name: 'Backend API', color: '#33FF57', ownerId: 'u2'),
  ]));

  // 3. Seed Tags
  await db.batch((batch) => batch.insertAll(db.tags, [
    TagsCompanion.insert(id: 't1', name: 'Urgent', color: '#FF0000'),
    TagsCompanion.insert(id: 't2', name: 'Frontend', color: '#0000FF'),
    TagsCompanion.insert(id: 't3', name: 'Backend', color: '#00FF00'),
  ]));

  // 4. Seed Tasks
  await db.batch(
    (batch) => batch.insertAll(db.tasks, [
      TasksCompanion.insert(
        id: '1',
        title: 'Design Database',
        status: 'todo',
        priority: 'high',
        projectId: 'p1',
        assigneeId: const Value('u2'),
        createdAt: DateTime.now(),
      ),
      TasksCompanion.insert(
        id: '2',
        title: 'Implement Repository',
        status: 'inProgress',
        priority: 'medium',
        projectId: 'p1',
        assigneeId: const Value('u1'),
        createdAt: DateTime.now(),
      ),
      TasksCompanion.insert(
        id: '3',
        title: 'Write Unit Tests',
        status: 'todo',
        priority: 'high',
        projectId: 'p1',
        assigneeId: const Value('u2'),
        createdAt: DateTime.now(),
      ),
      TasksCompanion.insert(
        id: '4',
        title: 'Setup CI/CD',
        status: 'todo',
        priority: 'low',
        projectId: 'p1',
        assigneeId: const Value('u1'),
        createdAt: DateTime.now(),
      ),
      TasksCompanion.insert(
        id: '5',
        title: 'Release to App Store',
        status: 'todo',
        priority: 'high',
        projectId: 'p1',
        assigneeId: const Value('u1'),
        createdAt: DateTime.now(),
      ),
    ]),
  );

  // 5. Seed TaskTags
  await db.batch((batch) => batch.insertAll(db.taskTags, [
    TaskTagsCompanion.insert(taskId: '1', tagId: 't3'),
    TaskTagsCompanion.insert(taskId: '2', tagId: 't3'),
    TaskTagsCompanion.insert(taskId: '5', tagId: 't1'),
  ]));
}
