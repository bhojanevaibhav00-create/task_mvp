import 'enums.dart';

extension TaskStatusX on TaskStatus {
  /// Returns the next status in the flow:
  /// To Do -> In Progress -> Review -> Done
  TaskStatus get next {
    switch (this) {
      case TaskStatus.todo:
        return TaskStatus.inProgress;
      case TaskStatus.inProgress:
        return TaskStatus.review;
      case TaskStatus.review:
        return TaskStatus.done;
      case TaskStatus.done:
        return TaskStatus.done; // No further state
    }
  }

  /// Returns a user-friendly label for the status.
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.review:
        return 'Review';
      case TaskStatus.done:
        return 'Done';
    }
  }

  /// Checks if the task is completed.
  bool get isCompleted => this == TaskStatus.done;
}
