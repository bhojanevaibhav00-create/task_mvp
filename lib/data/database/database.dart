import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
part 'database.g.dart';

// here is the database definition and no. of classes is actually a tables.
// These classes represent tables in your DB

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get dueTime => text().nullable()();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get priority => integer().nullable()();
  IntColumn get projectId => integer().nullable().references(Projects, #id)();
  IntColumn get tagId => integer().nullable().references(Tags, #id)();
  DateTimeColumn get createdAt =>
      dateTime().nullable().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable()();
  IntColumn get color => integer().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text().withLength(min: 1, max: 30)();
  IntColumn get colorHex => integer()();
}

class ActivityLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()();
  TextColumn get description => text().nullable()();
  IntColumn get taskId => integer().nullable()();
  IntColumn get projectId => integer().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // e.g., 'reminder', 'system', 'alert'
  TextColumn get title => text()();
  TextColumn get message => text()();
  IntColumn get taskId => integer().nullable().references(Tasks, #id)();
  IntColumn get projectId => integer().nullable().references(Projects, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
}

//Set Up the Database Class

@DriftDatabase(
  tables: [Tasks, Projects, Users, Tags, ActivityLogs, Notifications],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(projects);
          await m.createTable(users);
          await m.createTable(tags);
        }
        if (from < 2) {
          try {
            await m.addColumn(tasks, tasks.projectId as GeneratedColumn);
          } catch (e) {}
          try {
            await m.addColumn(tasks, tasks.tagId as GeneratedColumn);
          } catch (e) {}
          try {
            await m.addColumn(tasks, tasks.createdAt as GeneratedColumn);
          } catch (e) {}
          try {
            await m.addColumn(tasks, tasks.updatedAt as GeneratedColumn);
          } catch (e) {}
          try {
            await m.addColumn(tasks, tasks.completedAt as GeneratedColumn);
          } catch (e) {}
        }
        if (from < 22) {
          await m.createTable(activityLogs);
        }
        if (from < 3) {
          await m.renameColumn(
            projects,
            'title',
            projects.name as GeneratedColumn,
          );
          await m.addColumn(projects, projects.description as GeneratedColumn);
          await m.addColumn(projects, projects.color as GeneratedColumn);
          await m.addColumn(projects, projects.isArchived as GeneratedColumn);
          await m.addColumn(projects, projects.updatedAt as GeneratedColumn);
        }
        if (from < 4) {
          await m.createTable(notifications);
        }
        if (from < 5) {
          await m.addColumn(tasks, tasks.dueTime as GeneratedColumn);
          await m.addColumn(tasks, tasks.reminderAt as GeneratedColumn);
          await m.addColumn(tasks, tasks.reminderEnabled as GeneratedColumn);
        }
        if (from < 6) {
          await m.addColumn(
            activityLogs,
            activityLogs.taskId as GeneratedColumn,
          );
          await m.addColumn(
            activityLogs,
            activityLogs.projectId as GeneratedColumn,
          );
        }
      },
    );
  }

  Future<int> getDatabaseVersion() async {
    final result = await customSelect('PRAGMA user_version;').getSingle();
    return result.read<int>('user_version');
  }

  static QueryExecutor _openConnection() {
    // This handles finding the right folder on the device automatically
    return driftDatabase(name: 'my_app_database');
  }
}
