import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/notification_providers.dart';
import 'package:go_router/go_router.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final repo = ref.read(notificationRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              // Mark all as read
              final notifications =
                  await repo.listNotifications();
              for (final n in notifications) {
                if (!n.isRead) {
                  await repo.markRead(n.id);
                }
              }
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
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
                    n.isRead ? null : Colors.blue.shade50,
                leading: Icon(
                  n.isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: n.isRead
                      ? Colors.grey
                      : Colors.blue,
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
                  // mark as read
                  if (!n.isRead) {
                    await repo.markRead(n.id);
                  }

                  // deep link to task
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
