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

enum Priority { low, medium, high, critical }

enum SortCriteria { none, priorityHighToLow, priorityLowToHigh, tagAZ, tagZA }
