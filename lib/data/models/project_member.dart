import 'package:drift/drift.dart';
import 'project_role.dart';
/// Defines the 'ProjectMembers' table for the database.
/// Run `dart run build_runner build` to generate the `ProjectMember` data class.
@DataClassName('ProjectMember')
class ProjectMembers extends Table {
  IntColumn get projectId => integer()();
  IntColumn get userId => integer()();
  TextColumn get role =>
      text().withLength(min: 1, max: 20)(); // 'admin', 'editor', 'viewer'
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {projectId, userId};
}
