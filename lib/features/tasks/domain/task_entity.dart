enum TaskStatus { todo, inProgress, review, done }

class TaskEntity {
  final String id;
  final String title;
  final DateTime? dueDate;
  TaskStatus status;
  final DateTime createdAt;

  TaskEntity({
    required this.id,
    required this.title,
    this.dueDate,
    this.status = TaskStatus.todo,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
