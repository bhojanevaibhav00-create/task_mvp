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
/// ✅ STABLE: Uses maybeWhen to prevent the app from crashing or "hanging"
/// during high-frequency updates like task deletion or project merges.
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);
  
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});