import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../data/repositories/notification_repository.dart';
import 'task_providers.dart'; // ✅ Added to reuse the existing databaseProvider

/// =======================
/// NOTIFICATION REPOSITORY
/// =======================
final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  // ✅ REUSE: Uses the centralized databaseProvider from task_providers
  final db = ref.watch(databaseProvider);
  return NotificationRepository(db);
});

/// =======================
/// NOTIFICATIONS STREAM
/// =======================
/// This watches the database stream via the repository.
/// Any new assignment or member log will trigger this stream.
final notificationsStreamProvider =
    StreamProvider.autoDispose<List<Notification>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotifications();
});

/// =======================
/// UNREAD NOTIFICATION COUNT
/// =======================
/// ✅ ENTERPRISE READY: Real-time badge updates.
/// This provider reactively recalculates the count whenever the stream emits.
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);

  return notificationsAsync.when(
    data: (notifications) =>
        notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});