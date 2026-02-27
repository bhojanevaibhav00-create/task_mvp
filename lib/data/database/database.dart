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
  TextColumn get status => text().named('status').nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get dueTime => text().nullable()();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  BoolColumn get reminderEnabled =>
      boolean().named('reminder_enabled').withDefault(const Constant(false))();
  IntColumn get priority => integer().nullable()();
  IntColumn get projectId => integer().nullable().references(
    Projects,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get tagId => integer().nullable().references(Tags, #id)();
  IntColumn get assigneeId => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt =>
      dateTime().nullable().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// =======================
/// SUBTASKS
/// =======================
class Subtasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  BoolColumn get isCompleted =>
      boolean().named('is_completed').withDefault(const Constant(false))();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
}

/// =======================
/// COMMENTS
/// =======================
class Comments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
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
/// USERS
/// =======================
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get email => text().unique()();
  TextColumn get password => text()();
  TextColumn get bio => text().nullable()();
}

/// =======================
/// TAGS
/// =======================
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text().withLength(min: 1, max: 30)();
  IntColumn get colorHex => integer()();

  @override
  List<String> get customConstraints => ['UNIQUE(label COLLATE NOCASE)'];
}

/// =======================
/// ACTIVITY LOGS
/// =======================
class ActivityLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()();
  TextColumn get description => text().nullable()();
  IntColumn get taskId => integer().nullable().references(
    Tasks,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get projectId => integer().nullable().references(
    Projects,
    #id,
    onDelete: KeyAction.cascade,
  )();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

/// =======================
/// NOTIFICATIONS
/// =======================
class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get message => text()();
  IntColumn get taskId => integer().nullable().references(
    Tasks,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get projectId => integer().nullable().references(
    Projects,
    #id,
    onDelete: KeyAction.cascade,
  )();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isRead =>
      boolean().named('is_read').withDefault(const Constant(false))();
}

/// =======================
/// PROJECT MEMBERS
/// =======================
class ProjectMembers extends Table {
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text()();
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {projectId, userId};
}

/// =======================
/// LEADS (NEW MODULE)
/// =======================
class Leads extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get companyName => text().withLength(min: 1, max: 100)();
  TextColumn get contactPersonName => text().withLength(min: 1, max: 100)();
  TextColumn get mobile => text()();
  TextColumn get email => text().nullable()();
  TextColumn get productPitched => text().nullable()();
  TextColumn get discussion => text().nullable()();
  DateTimeColumn get followUpDate => dateTime().nullable()();
  TextColumn get followUpTime => text().nullable()();
  TextColumn get status => text()();
  IntColumn get ownerId => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// =======================
/// DATABASE CONFIG
/// =======================
@DriftDatabase(
  tables: [
    Tasks,
    Subtasks,
    Comments,
    Projects,
    Users,
    Tags,
    ActivityLogs,
    Notifications,
    ProjectMembers,
    Leads, // 👈 Added
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 13; // 👈 Updated

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async => await m.createAll(),
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 13) {
          await m.createTable(leads);
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'my_app_database_v2');
  }
}
