import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
part 'database.g.dart';

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
  DateTimeColumn get createdAt => dateTime().nullable().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get assigneeId => integer().nullable().references(Users, #id)();
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
  
  TextColumn get email => text().nullable()(); 
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



@DriftDatabase(
  tables: [Tasks, Projects, Users, Tags, ActivityLogs, Notifications, ProjectMembers],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
Future<int> getDatabaseVersion() async {
    final result = await customSelect('PRAGMA user_version;').getSingle();
    return result.read<int>('user_version');
  }
  
  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 7) {
          await m.createTable(activityLogs);
          await m.createTable(notifications);
          await m.createTable(projectMembers);
          await m.addColumn(tasks, tasks.assigneeId);
        }
        
        if (from < 8) {
          await m.addColumn(users, users.email);
        }
      },
    );
  }

  static QueryExecutor _openConnection() => driftDatabase(name: 'my_app_database');
}