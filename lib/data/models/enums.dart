import 'package:flutter/material.dart';

enum TaskStatus {
  todo,
  inProgress,
  review,
  done;

  String get dbValue {
    switch (this) {
      case TaskStatus.inProgress:
        return 'in_progress';
      default:
        return name;
    }
  }
}

enum Priority {
  low,
  medium,
  high,
}

extension PriorityExtension on Priority {
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

  String get label {
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
