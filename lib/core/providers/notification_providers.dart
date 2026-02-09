import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../data/repositories/notification_repository.dart';
import 'package:task_mvp/core/providers/database_provider.dart';
/// =======================
/// DATABASE PROVIDER
/// =======================
/// ⚠️ If this already exists elsewhere,
/// reuse that instead of duplicating

/// =======================
/// NOTIFICATION REPOSITORY
/// =======================
final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NotificationRepository(db);
});

/// =======================
/// NOTIFICATIONS STREAM
/// =======================
final notificationsStreamProvider =
    StreamProvider<List<Notification>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotifications();
});

/// =======================
/// UNREAD NOTIFICATION COUNT
/// =======================
/// ✅ SAFE | ✅ NO CRASH | ✅ BADGE READY
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);

  return notificationsAsync.when(
    data: (notifications) =>
        notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
