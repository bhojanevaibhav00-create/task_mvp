import 'enums.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final Priority priority;
  final List<Tag> tags;
  final DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.tags,
    this.dueDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    status: TaskStatus.values.byName(json['status']), // Maps string to Enum
    priority: Priority.values.byName(json['priority']),
    tags: (json['tags'] as List).map((t) => Tag.fromJson(t)).toList(),
    dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
  );
}

// to this model work, make sure to import enums.dart where needed and use
// example: final task = Task.fromJson(yourJsonMap) to parse a Task object.
