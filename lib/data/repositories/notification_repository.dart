import 'package:drift/drift.dart';
import '../database/database.dart';

class NotificationRepository {
  final AppDatabase _db;

  NotificationRepository(this._db);

  /// Adds a new notification.
  Future<int> addNotification(NotificationsCompanion notification) {
    return _db.into(_db.notifications).insert(notification);
  }

  /// Lists all notifications, ordered by creation date (newest first).
  Future<List<Notification>> listNotifications() {
    return (_db.select(_db.notifications)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  /// Watches notifications for real-time UI updates.
  Stream<List<Notification>> watchNotifications() {
    return (_db.select(_db.notifications)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  /// Marks a specific notification as read.
  Future<void> markRead(int id) {
    return (_db.update(_db.notifications)..where((t) => t.id.equals(id))).write(
      const NotificationsCompanion(isRead: Value(true)),
    );
  }

  /// Clears all notifications (optional MVP feature).
  Future<int> clearAll() {
    return _db.delete(_db.notifications).go();
  }
}
