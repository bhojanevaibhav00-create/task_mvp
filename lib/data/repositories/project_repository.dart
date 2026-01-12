import '../database/database.dart';

class ProjectRepository {
  final AppDatabase _db;

  ProjectRepository(this._db);

  // Create
  Future<int> createProject(ProjectsCompanion project) async {
    return await _db.into(_db.projects).insert(project);
  }

  // Read
  Future<List<Project>> getAllProjects() async {
    return await _db.select(_db.projects).get();
  }

  // Delete
  Future<int> deleteProject(int id) async {
    return await (_db.delete(_db.projects)..where((p) => p.id.equals(id))).go();
  }
}
