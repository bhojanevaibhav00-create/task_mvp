import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// =======================
/// TABLE DEFINITIONS
/// =======================

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

  IntColumn get projectId =>
      integer().nullable().references(Projects, #id)();

  IntColumn get tagId =>
      integer().nullable().references(Tags, #id)();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable()();
  IntColumn get color => integer().nullable()();

  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

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

  DateTimeColumn get timestamp =>
      dateTime().withDefault(currentDateAndTime)();
}

class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get type => text()(); // reminder / system
  TextColumn get title => text()();
  TextColumn get message => text()();

  IntColumn get taskId =>
      integer().nullable().references(Tasks, #id)();

  IntColumn get projectId =>
      integer().nullable().references(Projects, #id)();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  BoolColumn get isRead =>
      boolean().withDefault(const Constant(false))();
}

/// =======================
/// DATABASE
/// =======================

@DriftDatabase(
  tables: [
    Tasks,
    Projects,
    Users,
    Tags,
    ActivityLogs,
    Notifications,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Schema version
  @override
  int get schemaVersion => 6;

  /// ✅ FIXED: Database version getter (USED BY REPOSITORY)
  Future<int> getDatabaseVersion() async {
    final result =
        await customSelect('PRAGMA user_version;').getSingle();
    return result.read<int>('user_version');
  }

  /// Migrations
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (Migrator m, int from, int to) async {
        // v1 → v2
        if (from < 2) {
          await m.createTable(projects);
          await m.createTable(users);
          await m.createTable(tags);

          await m.addColumn(tasks, tasks.projectId);
          await m.addColumn(tasks, tasks.tagId);
          await m.addColumn(tasks, tasks.createdAt);
          await m.addColumn(tasks, tasks.updatedAt);
          await m.addColumn(tasks, tasks.completedAt);
        }

        // v2 → v3 (Project enhancements)
        if (from < 3) {
          await m.addColumn(projects, projects.description);
          await m.addColumn(projects, projects.color);
          await m.addColumn(projects, projects.isArchived);
          await m.addColumn(projects, projects.updatedAt);
        }

        // v3 → v4
        if (from < 4) {
          await m.createTable(notifications);
        }

        // v4 → v5
        if (from < 5) {
          await m.addColumn(tasks, tasks.dueTime);
          await m.addColumn(tasks, tasks.reminderAt);
          await m.addColumn(tasks, tasks.reminderEnabled);
        }

        // v5 → v6
        if (from < 6) {
          await m.createTable(activityLogs);
        }
      },
    );
  }

  /// DB connection
  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'my_app_database');
  }
}
