import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/notification_providers.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ WATCH: Real-time stream for the UI
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    // ✅ READ: Repository for actions
    final repo = ref.read(notificationRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          notificationsAsync.when(
            data: (list) => list.any((n) => !n.isRead) 
              ? TextButton(
                  onPressed: () async {
                    // ✅ FIXED: Using the actual list from the provider 
                    // to avoid calling a non-existent repo.listNotifications()
                    for (final n in list) {
                      if (!n.isRead) await repo.markAsRead(n.id);
                    }
                  },
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _buildNotificationCard(context, n, repo);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, dynamic n, dynamic repo) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () async {
            // 1. ✅ FIXED: markAsRead (matches repository naming)
            if (!n.isRead) await repo.markAsRead(n.id);
            
            // 2. Deep Linking
            if (n.taskId != null) {
              context.push('/tasks/${n.taskId}');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeadingIcon(n.isRead, n.type),
                const SizedBox(width: 16),
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
                                fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w900,
                                fontSize: 15,
                                color: n.isRead ? Colors.black45 : const Color(0xFF1A1C1E),
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(n.createdAt),
                            style: const TextStyle(fontSize: 11, color: Colors.black26),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.message, // ✅ Uses 'message' column from database.g.dart
                        style: TextStyle(
                          fontSize: 13,
                          color: n.isRead ? Colors.black26 : Colors.black54,
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
    );
  }

  Widget _buildLeadingIcon(bool isRead, String type) {
    IconData iconData = Icons.notifications_none_rounded;
    if (type == 'assignment') iconData = Icons.assignment_ind_rounded;
    if (type == 'task') iconData = Icons.checklist_rtl_rounded;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey.shade50 : AppColors.primary.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: isRead ? Colors.grey.shade300 : AppColors.primary,
        size: 20,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your notifications will appear here.',
            style: TextStyle(color: Colors.black26),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}