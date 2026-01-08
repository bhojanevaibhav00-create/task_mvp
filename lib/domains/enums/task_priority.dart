enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  String get value => name;

  static TaskPriority fromString(String value) {
    return TaskPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskPriority.medium,
    );
  }
}
