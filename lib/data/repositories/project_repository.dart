import 'package:app_data_demo/data/database/database.dart';

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

  Stream<List<Project>> watchAllProjects() {
    return _db.select(_db.projects).watch();
  }

  Future<Project?> getProjectById(int id) async {
    return await (_db.select(
      _db.projects,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  // Update
  Future<bool> updateProject(Project project) async {
    return await _db.update(_db.projects).replace(project);
  }

  // Delete
  Future<int> deleteProject(int id) async {
    return await (_db.delete(_db.projects)..where((p) => p.id.equals(id))).go();
  }
}

/*
How to use ProjectRepository:

1. Initialize the database and repository:
   final db = AppDatabase();
   final projectRepo = ProjectRepository(db);

2. Create a project:
   await projectRepo.createProject(
     ProjectsCompanion.insert(
       title: 'New Project',
       createdAt: DateTime.now(),
     ),
   );

3. Get all projects:
   final projects = await projectRepo.getAllProjects();

4. Watch projects (for StreamBuilder):
   Stream<List<Project>> projectStream = projectRepo.watchAllProjects();

5. Update a project:
   // Assuming you have a 'project' object from the DB
   final updatedProject = project.copyWith(title: 'Updated Title');
   await projectRepo.updateProject(updatedProject);

6. Delete a project:
   await projectRepo.deleteProject(projectId);
*/
