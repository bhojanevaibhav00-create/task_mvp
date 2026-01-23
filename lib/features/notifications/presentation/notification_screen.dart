import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/notification_providers.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final repo = ref.read(notificationRepositoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1A1C1E),
        actions: [
          // Styled TextButton for 'Mark all read'
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () async {
                final notifications = await repo.listNotifications();
                for (final n in notifications) {
                  if (!n.isRead) await repo.markRead(n.id);
                }
              },
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final n = notifications[index];

              return _buildNotificationCard(context, n, repo, theme);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, dynamic n, dynamic repo, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              if (!n.isRead) await repo.markRead(n.id);
              if (n.taskId != null) context.go('/tasks/${n.taskId}');
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with dynamic indicator
                  _buildLeadingIcon(n.isRead),
                  const SizedBox(width: 16),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                n.title,
                                style: TextStyle(
                                  fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                                  fontSize: 15,
                                  color: n.isRead ? Colors.grey.shade700 : const Color(0xFF1A1C1E),
                                ),
                              ),
                            ),
                            Text(
                              _formatTime(n.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: n.isRead ? Colors.grey.shade500 : Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(bool isRead) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isRead ? Colors.grey.shade100 : AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
            color: isRead ? Colors.grey.shade400 : AppColors.primary,
            size: 22,
          ),
        ),
        if (!isRead)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              height: 10,
              width: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Quiet for now',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll let you know when something\nimportant happens.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, height: 1.5),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}