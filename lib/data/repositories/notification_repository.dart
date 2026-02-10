import 'package:drift/drift.dart';
import '../database/database.dart';

class NotificationRepository {
  final AppDatabase _db;

  NotificationRepository(this._db);

  /// ✅ FIXED: Matches the 'message' column in your generated database
  Future<int> addNotification({
    required String title,
    required String body,
    required String type,
  }) {
    return _db.into(_db.notifications).insert(
      NotificationsCompanion(
        title: Value(title),
        message: Value(body), // 'message' is the column, 'body' is the input string
        type: Value(type),
        isRead: const Value(false),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<Notification>> watchNotifications() {
    return (_db.select(_db.notifications)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<void> markAsRead(int id) {
    return (_db.update(_db.notifications)..where((t) => t.id.equals(id))).write(
      const NotificationsCompanion(isRead: Value(true)),
    );
  }

  Future<int> deleteAllNotifications() {
    return _db.delete(_db.notifications).go();
  }
}