import '../models/task_model.dart';
import '../models/enums.dart';
import '../models/tag_model.dart';

class SeedData {
  static List<Task> getTasks() {
    final now = DateTime.now();

    final tagUrgent = Tag(id: '1', label: 'Urgent', colorHex: 0xFFFF0000);
    final tagWork = Tag(id: '2', label: 'Work', colorHex: 0xFF0000FF);
    final tagHome = Tag(id: '3', label: 'Home', colorHex: 0xFF00FF00);

    return [
      Task(
        id: '1',
        title: 'Complete Project Documentation',
        description: 'Write the README and API docs.',
        status: TaskStatus.inProgress,
        priority: Priority.high,
        tags: [tagWork, tagUrgent],
        dueDate: now.add(const Duration(days: 1)),
      ),
      Task(
        id: '2',
        title: 'Grocery Shopping',
        description: 'Buy milk, eggs, and bread.',
        status: TaskStatus.todo,
        priority: Priority.medium,
        tags: [tagHome],
        dueDate: now, // Today
      ),
      Task(
        id: '3',
        title: 'Team Meeting',
        description: 'Weekly sync with the design team.',
        status: TaskStatus.done,
        priority: Priority.low,
        tags: [tagWork],
        dueDate: now.subtract(const Duration(days: 2)), // Past
      ),
      Task(
        id: '4',
        title: 'Code Review',
        description: 'Review the PR for the new feature.',
        status: TaskStatus.review,
        priority: Priority.high,
        tags: [tagWork],
        dueDate: now.add(const Duration(days: 3)),
      ),
    ];
  }
}
