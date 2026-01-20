import 'package:task_mvp/data/database/database.dart';

class ReminderService {
  final AppDatabase _db;

  ReminderService(this._db);

  /// Called when task is created / updated
  Future<void> schedule(Task task) async {
    if (task.reminderEnabled != true || task.reminderAt == null) return;

    // TODO: replace with real local notification scheduling
    print('Scheduling reminder for task ${task.id}');
  }

  /// Called when task is completed or reminder disabled
  Future<void> cancel(int taskId) async {
    // TODO: cancel local notification
    print('Cancel reminder for task $taskId');
  }

  /// Called on app start to rebuild reminders
  Future<void> resyncOnAppStart() async {
    final tasks = await (_db.select(_db.tasks)
          ..where((t) => t.reminderEnabled.equals(true))
          ..where((t) => t.reminderAt.isNotNull())
          ..where((t) => t.status.isNotValue('done')))
        .get();

    for (final task in tasks) {
      await schedule(task);
    }
  }
}
