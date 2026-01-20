import 'package:flutter/material.dart';
enum TaskStatus {
  todo,
  inProgress,
  review,
  done,
}

enum Priority {
  low,
  medium,
  high,
}
extension PriorityExtension on Priority {
  // Returns a color for each priority
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

  // Optional: return a name string
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
