import 'enums.dart';
import 'tag_model.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final Priority priority;
  final DateTime? dueDate;
  final bool important;
  final List<Tag> tags;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.status = TaskStatus.todo,
    this.priority = Priority.medium,
    this.dueDate,
    this.important = false,
    this.tags = const [],
  });

  /// ✅ ADD THIS METHOD
  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    Priority? priority,
    DateTime? dueDate,
    bool? important,
    List<Tag>? tags,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      important: important ?? this.important,
      tags: tags ?? this.tags,
    );
  }
}
