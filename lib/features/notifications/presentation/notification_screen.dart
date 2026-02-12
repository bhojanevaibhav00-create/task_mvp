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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
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
            data: (list) => list.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: 'Clear All',
                  onPressed: () => _showClearAllDialog(context, repo, isDark),
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
            return _buildEmptyState(isDark);
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final n = notifications[index];
              
              return Dismissible(
                // Use a unique key combined with the list length to ensure stability
                key: ValueKey('notification_${n.id}'),
                direction: DismissDirection.endToStart,
                
                // ✅ GUARD: Ensures the item is actually removed from DB
                onDismissed: (direction) async {
                  await repo.deleteNotification(n.id);
                  // Use a scaffold messenger to show a brief confirmation
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Notification deleted"), duration: Duration(seconds: 1)),
                    );
                  }
                },
                
                background: _buildDeleteBackground(),
                child: _buildNotificationCard(context, n, repo, isDark),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.redAccent.shade400,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, dynamic n, dynamic repo, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () async {
            if (!n.isRead) await repo.markAsRead(n.id);
            if (n.taskId != null) {
              context.push('/tasks/${n.taskId}');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeadingIcon(n.isRead, n.type, isDark),
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
                                color: n.isRead 
                                  ? (isDark ? Colors.white38 : Colors.black45) 
                                  : (isDark ? Colors.white : const Color(0xFF1A1C1E)),
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(n.createdAt),
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.black26),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.message, 
                        style: TextStyle(
                          fontSize: 13,
                          color: n.isRead 
                            ? (isDark ? Colors.white24 : Colors.black26) 
                            : (isDark ? Colors.white70 : Colors.black54),
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

  Widget _buildLeadingIcon(bool isRead, String type, bool isDark) {
    IconData iconData = Icons.notifications_none_rounded;
    if (type == 'assignment') iconData = Icons.assignment_ind_rounded;
    if (type == 'task') iconData = Icons.checklist_rtl_rounded;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isRead 
          ? (isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50) 
          : AppColors.primary.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: isRead 
          ? (isDark ? Colors.white12 : Colors.grey.shade300) 
          : AppColors.primary,
        size: 20,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1A1C1E)),
          ),
          const SizedBox(height: 8),
          Text(
            'Your notifications will appear here.',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black26),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, dynamic repo, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        title: const Text('Clear all notifications?'),
        content: const Text('This will remove all history permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await repo.deleteAllNotifications();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}