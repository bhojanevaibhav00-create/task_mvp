import 'enums.dart';
import 'tag_model.dart';

class Task {
  final String id;
  final String title;
  final bool important;
  final String? description;
  final DateTime? dueDate;
  final Priority priority;
  TaskStatus status;
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

  Task copyWith({
    TaskStatus? status,
  }) {
    return Task(
      id: id,
      title: title,
      important: important,
      description: description,
      dueDate: dueDate,
      priority: priority,
      status: status ?? this.status,
      tags: tags,
    );
  }
}
