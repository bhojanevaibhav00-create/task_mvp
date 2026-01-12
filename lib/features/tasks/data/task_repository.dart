import '../domain/task_entity.dart';
import 'dart:math';

class TaskRepository {
  static final List<TaskEntity> _tasks = [];

  static List<TaskEntity> fetchTasks() => List.unmodifiable(_tasks);

  static void addTask(String title) {
    _tasks.add(
      TaskEntity(
        id: Random().nextInt(999999).toString(),
        title: title,
      ),
    );
  }

  static void updateTask(TaskEntity task) {
    // in-memory update (reference based)
  }
}
