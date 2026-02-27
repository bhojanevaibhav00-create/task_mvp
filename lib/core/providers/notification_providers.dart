import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
// ✅ CRITICAL: Aliasing avoids conflict with Flutter's Material Notification class
import '../../data/database/database.dart' as db;
import '../../data/repositories/notification_repository.dart';
import 'package:task_mvp/core/providers/database_provider.dart';

/// =======================================================
/// 1. NOTIFICATION REPOSITORY PROVIDER
/// =======================================================
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return NotificationRepository(database);
});

/// =======================================================
/// 2. NOTIFICATIONS STREAM (The UI Source)
/// =======================================================
/// ✅ FIXED: StreamProvider.autoDispose ensures the database connection 
/// closes when the user leaves the notification screen.
final notificationsStreamProvider = StreamProvider.autoDispose<List<db.Notification>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotifications();
});

/// =======================================================
/// 3. UNREAD COUNT LOGIC (The Badge Source)
/// =======================================================
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);
  
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

/// =======================================================
/// 4. NOTIFICATION NOTIFIER (The Logic Source)
/// =======================================================
/// ✅ NEW: Add this to allow other controllers to trigger notifications.
final notificationServiceProvider = Provider((ref) => NotificationNotifier(ref));

class NotificationNotifier {
  final Ref ref;
  NotificationNotifier(this.ref);

  /// Standard method to inject a new notification into the DB
  Future<void> sendNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final database = ref.read(databaseProvider);
    
    await database.into(database.notifications).insert(
      db.NotificationsCompanion.insert(
        title: title,
        message: body,
        type: type,
        isRead: const Value(false),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  /// Mark all as read (useful for the Notification Screen "Clear All")
  Future<void> markAllAsRead() async {
    final database = ref.read(databaseProvider);
    await (database.update(database.notifications)
          ..where((t) => t.isRead.equals(false)))
        .write(const db.NotificationsCompanion(isRead: Value(true)));
  }
}
