enum TaskStatus { todo, inProgress, review, done }

class TaskEntity {
  final String id;
  final String title;
  TaskStatus status;

  TaskEntity({
    required this.id,
    required this.title,
    this.status = TaskStatus.todo,
  });
}
