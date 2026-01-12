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
  TextColumn get title => text().withLength(min: 1, max: 50)();
  DateTimeColumn get createdAt => dateTime()();
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
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

//Set Up the Database Class

@DriftDatabase(tables: [Tasks, Projects, Users, Tags, ActivityLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

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
