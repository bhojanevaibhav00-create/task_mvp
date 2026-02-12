import 'package:drift/drift.dart';
import '../database/database.dart';

class NotificationRepository {
  final AppDatabase _db;

  NotificationRepository(this._db);

  /// ✅ FIXED: Added this method to match the Notifier's call
  Future<int> insertNotification(NotificationsCompanion companion) {
    return _db.into(_db.notifications).insert(companion);
  }

  /// ✅ ALIGNED: Uses 'message' to match TaskRepository calls
  Future<int> addNotification({
    required String title,
    required String message, 
    required String type,
    int? taskId,
    int? projectId,
  }) {
    return _db.into(_db.notifications).insert(
      NotificationsCompanion.insert(
        title: title,
        message: message, 
        type: type,
        taskId: Value(taskId),
        projectId: Value(projectId),
        isRead: const Value(false),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  /// ✅ REACTIVE: Watches notifications and sorts by newest first
  Stream<List<Notification>> watchNotifications() {
    return (_db.select(_db.notifications)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// ✅ UPDATE: Mark a specific notification as read
  Future<void> markAsRead(int id) {
    return (_db.update(_db.notifications)..where((t) => t.id.equals(id))).write(
      const NotificationsCompanion(isRead: Value(true)),
    );
  }

  /// ✅ UPDATE: Mark all notifications as read at once
  Future<void> markAllAsRead() {
    return (_db.update(_db.notifications)..where((t) => t.isRead.equals(false)))
        .write(const NotificationsCompanion(isRead: Value(true)));
  }

  /// ✅ NEW: Specific method for single item deletion
  /// This prevents the "Error Page" crash when using the Dismissible widget.
  Future<int> deleteNotification(int id) {
    return (_db.delete(_db.notifications)..where((t) => t.id.equals(id))).go();
  }

  /// ✅ DELETE: Clear notification history
  Future<int> deleteAllNotifications() {
    return _db.delete(_db.notifications).go();
  }
}