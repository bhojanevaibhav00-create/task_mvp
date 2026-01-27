import 'task_model.dart';

//Its a project model containing name and task.
class Project {
  final String name;
  final List<Task> tasks;

  Project({required this.name, required this.tasks});
}
