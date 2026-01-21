class Task {
  String title;
  DateTime? dueDate;
  bool isCompleted;
  bool isImportant;
  String priority; // "High", "Medium", "Low"
  List<String> tags;

  Task({
    required this.title,
    this.dueDate,
    this.isCompleted = false,
    this.isImportant = false,
    this.priority = "Low",
    List<String>? tags,
  }) : tags = tags ?? [];
}
