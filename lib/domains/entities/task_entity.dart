import '../enums/task_priority.dart';
import '../enums/task_status.dart';

class TaskEntity {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final String projectId;
  final String? assigneeId;
  final DateTime createdAt;

  TaskEntity({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.projectId,
    this.assigneeId,
    required this.createdAt,
  });
}
