class ActivityLog {
  final int id;
  final String action;
  final String? description;
  final int? taskId;
  final int? projectId;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.action,
    this.description,
    this.taskId,
    this.projectId,
    required this.timestamp,
  });
}