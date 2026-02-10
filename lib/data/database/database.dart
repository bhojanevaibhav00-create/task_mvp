import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// =======================
/// TASKS
/// =======================
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get dueTime => text().nullable()();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(false))();
  IntColumn get priority => integer().nullable()();
  IntColumn get projectId => integer().nullable().references(Projects, #id)();
  IntColumn get tagId => integer().nullable().references(Tags, #id)();
  IntColumn get assigneeId => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().nullable().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// =======================
/// PROJECTS
/// =======================
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable()();
  IntColumn get color => integer().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// =======================
/// USERS (Merged: Added Password & Unique Email)
/// =======================
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get email => text().unique()(); // Enforces unique login emails
  TextColumn get password => text()(); // Mandatory for Auth
}

/// =======================
/// OTHER TABLES (Tags, ActivityLogs, Notifications, ProjectMembers)
/// =======================
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
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get message => text()();
  IntColumn get taskId => integer().nullable().references(Tasks, #id)();
  IntColumn get projectId => integer().nullable().references(Projects, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
}

class ProjectMembers extends Table {
  IntColumn get projectId => integer().references(Projects, #id)();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get role => text()();
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {projectId, userId};
}

/// =======================
/// DATABASE CONFIG & MIGRATION
/// =======================
@DriftDatabase(
  tables: [
    Tasks,
    Projects,
    Users,
    Tags,
    ActivityLogs,
    Notifications,
    ProjectMembers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // ✅ Essential for AuthRepository & TaskRepository
  Future<int> getDatabaseVersion() async {
    final result = await customSelect('PRAGMA user_version;').getSingle();
    return result.read<int>('user_version');
  }

  @override
  int get schemaVersion => 9; // ✅ Unified version

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async => await m.createAll(),
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(projects);
          await m.createTable(users);
          await m.createTable(tags);
          await m.addColumn(tasks, tasks.projectId);
          await m.addColumn(tasks, tasks.tagId);
        }
        if (from < 3) {
          await m.addColumn(projects, projects.description);
          await m.addColumn(projects, projects.color);
        }
        if (from < 5) {
          await m.addColumn(tasks, tasks.dueTime);
          await m.addColumn(tasks, tasks.reminderAt);
          await m.addColumn(tasks, tasks.reminderEnabled);
        }
        if (from < 8) {
          // ✅ Critical: Adding password field for current users
          try {
            await m.addColumn(users, users.password);
          } catch (e) {
            // Already exists in some environments
          }
        }
        if (from < 9) {
          // Full schema synchronization for notifications and members
          try {
            await m.createTable(notifications);
            await m.createTable(activityLogs);
            await m.createTable(projectMembers);
            await m.addColumn(tasks, tasks.assigneeId);
          } catch (e) {
            // Log as no-op if tables exist
          }
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'my_app_database');
  }
}