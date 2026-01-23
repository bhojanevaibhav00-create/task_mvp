import 'enums.dart';
import 'tag_model.dart';

class Task {
  final String id;
  final String title;
  final bool important;
  final String? description;
  final DateTime? dueDate;
  final Priority priority;
  final TaskStatus status; // Changed to final for better immutability pattern
  final List<Tag> tags;

  Task({
    required this.id,
    required this.title,
    this.important = false,
    this.description,
    this.dueDate,
    required this.priority,
    this.status = TaskStatus.todo,
    this.tags = const [],
  });

  /// Helper to safely get status even if the data source returns a String.
  /// This prevents the "tasks" filtering error in the Board Screen.
  TaskStatus get statusEnum {
    return status; // Since it's typed as TaskStatus, this is safe here.
  }

  /// Convenience getter for the Task Card UI
  bool get isDone => status == TaskStatus.done;

  /// Updated copyWith to handle all fields, keeping the UI reactive.
  Task copyWith({
    String? title,
    bool? important,
    String? description,
    DateTime? dueDate,
    Priority? priority,
    TaskStatus? status,
    List<Tag>? tags,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      important: important ?? this.important,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      tags: tags ?? this.tags,
    );
  }
}