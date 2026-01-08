import 'package:app_data_demo/data/database/database.dart';

class TaskRepository {
  final AppDatabase _db;

  TaskRepository(this._db);

  // Create
  Future<int> createTask(TasksCompanion task) async {
    return await _db.into(_db.tasks).insert(task);
  }

  // Read
  Future<List<Task>> getAllTasks() async {
    return await _db.select(_db.tasks).get();
  }

  Stream<List<Task>> watchAllTasks() {
    return _db.select(_db.tasks).watch();
  }

  Future<Task?> getTaskById(int id) async {
    return await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // Update
  Future<bool> updateTask(Task task) async {
    return await _db.update(_db.tasks).replace(task);
  }

  // Delete
  Future<int> deleteTask(int id) async {
    return await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }
}

/*
How to use TaskRepository:

1. Initialize the database and repository:
   final db = AppDatabase();
   final taskRepo = TaskRepository(db);

2. Create a task:
   await taskRepo.createTask(
     TasksCompanion.insert(
       title: 'New Task',
       description: const Value('Task description'),
       status: const Value('todo'),
     ),
   );

3. Get all tasks:
   final tasks = await taskRepo.getAllTasks();

4. Watch tasks (for StreamBuilder):
   Stream<List<Task>> taskStream = taskRepo.watchAllTasks();

5. Update a task:
   // Assuming you have a 'task' object from the DB
   final updatedTask = task.copyWith(title: 'Updated Task Title');
   await taskRepo.updateTask(updatedTask);

6. Delete a task:
   await taskRepo.deleteTask(taskId);
*/
