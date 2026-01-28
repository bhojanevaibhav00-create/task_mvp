import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/notification_providers.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final repo = ref.read(notificationRepositoryProvider);

    return Scaffold(
      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient, // ✅ SAME AS DASHBOARD
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final notifications = await repo.listNotifications();
              for (final n in notifications) {
                if (!n.isRead) {
                  await repo.markRead(n.id);
                }
              }
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      // ================= BODY =================
      body: notificationsAsync.when(
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];

              return ListTile(
                tileColor:
                n.isRead ? null : AppColors.primarySoft,
                leading: Icon(
                  n.isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color:
                  n.isRead ? Colors.grey : AppColors.primary,
                ),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight:
                    n.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(n.message),
                trailing: Text(
                  _formatTime(n.createdAt),
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  if (!n.isRead) {
                    await repo.markRead(n.id);
                  }

                  if (n.taskId != null) {
                    context.go('/tasks/${n.taskId}');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
