import 'task_model.dart';

class Project {
  final String name;
  final List<Task> tasks;

  Project({
    required this.name,
    required this.tasks,
  });
}
