import 'package:flutter_riverpod/flutter_riverpod.dart';
// ✅ CRITICAL: Aliasing avoids conflict with Flutter's Material Notification class
import '../../data/database/database.dart' as db;
import '../../data/repositories/notification_repository.dart';
import 'task_providers.dart'; 

/// =======================
/// NOTIFICATION REPOSITORY
/// =======================
/// ✅ FIXED: Changed to watch the databaseProvider once to avoid unnecessary rebuilds
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return NotificationRepository(database);
});

/// =======================
/// NOTIFICATIONS STREAM
/// =======================
/// ✅ FIXED: Using autoDispose to clear memory, but ensuring it only watches the repo.
/// This provides the data for the Notification screen and the unread count.
final notificationsStreamProvider =
    StreamProvider.autoDispose<List<db.Notification>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotifications();
});

/// =======================
/// UNREAD NOTIFICATION COUNT
/// =======================
/// ✅ FIXED: Simplified logic to prevent circular triggers during 'ref.invalidate'
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  // We use .whenData to transform the stream specifically without a full 'when' block
  // which is safer during heavy state refreshes like task deletion.
  return ref.watch(notificationsStreamProvider).maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});