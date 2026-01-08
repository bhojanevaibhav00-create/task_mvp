enum TaskStatus { todo, inProgress, done }

extension TaskStatusX on TaskStatus {
  String get value => name;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskStatus.todo,
    );
  }
}
