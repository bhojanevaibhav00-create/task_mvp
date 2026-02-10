import 'package:drift/drift.dart';
import '../database/database.dart';

class NotificationRepository {
  final AppDatabase _db;

  NotificationRepository(this._db);

  /// ✅ ALIGNED: Uses 'message' to match TaskRepository calls
  /// ✅ FEATURE: Added taskId and projectId for better traceability
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