import 'package:flutter/material.dart';

enum Priority { low, medium, high }

extension PriorityX on Priority {
  Color get color {
    switch (this) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }

  String get name {
    switch (this) {
      case Priority.low:
        return "Low";
      case Priority.medium:
        return "Medium";
      case Priority.high:
        return "High";
    }
  }
}

enum TaskStatus { todo, inProgress, done,review }

extension TaskStatusX on TaskStatus {
  Color get color {
    switch (this) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.done:
        return Colors.green;
      case TaskStatus.review:
        return Colors.white;
    }
  }

  String get name {
    switch (this) {
      case TaskStatus.todo:
        return "To Do";
      case TaskStatus.inProgress:
        return "In Progress";
      case TaskStatus.done:
        return "Done";
      case TaskStatus.review:
        return "Review";
    }
  }
}
