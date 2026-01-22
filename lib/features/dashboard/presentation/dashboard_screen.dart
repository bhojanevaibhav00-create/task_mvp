import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:task_mvp/core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/tag_model.dart';
import '../../notifications/presentation/notification_screen.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/filter_bottom_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    final completed =
        tasks.where((t) => t.status == TaskStatus.done.name).length;
    final pending =
        tasks.where((t) => t.status != TaskStatus.done.name).length;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ================= APP BAR =================
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Dashboard'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.9),
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              // Notifications
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.red,
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),

              // Filter button
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  openFilterBottomSheet(
                    context: context,
                    allTags: [],
                    statusFilters: {},
                    priorityFilters: {},
                    tagFilters: {},
                    dueBucket: null,
                    sort: null,
                    onApply: (status, priority, tags, due, sort) {
                      // Your filter logic
                    },
                  );
                },
              ),
            ],
          ),

          // ================= BODY =================
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // ================= SUMMARY CARDS =================
                Row(
                  children: [
                    _summaryCard(
                        context, 'Total', tasks.length.toString(), Icons.list_alt, Colors.blue, isDark),
                    const SizedBox(width: 12),
                    _summaryCard(
                        context, 'Pending', pending.toString(), Icons.pending_actions, Colors.orange, isDark),
                    const SizedBox(width: 12),
                    _summaryCard(
                        context, 'Done', completed.toString(), Icons.check_circle, Colors.green, isDark),
                  ],
                ),

                const SizedBox(height: 24),

                // ================= QUICK ACTIONS =================
                const Text('Quick Actions',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppButton(
                      text: 'View Tasks',
                      onPressed: () => context.push(AppRoutes.tasks),
                    ),
                    AppButton(
                      text: 'Add Task',
                      onPressed: () => context.push(AppRoutes.tasks),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ================= RECENT TASKS =================
                const Text('Recent Tasks',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (tasks.isEmpty)
                  _emptyState(context, isDark)
                else
                  ...tasks.take(5).map((task) {
                    final isDone = task.status == TaskStatus.done.name;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Theme.of(context).cardColor
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(AppColors.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black26
                                : Colors.black12,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDone
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isDone ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_forward_ios,
                                size: 16,
                                color: isDark ? Colors.white : Colors.black87),
                            onPressed: () =>
                                context.push(AppRoutes.tasks),
                          ),
                        ],
                      ),
                    );
                  }),
              ]),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.tasks),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, String title, String value,
      IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black12,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).cardColor
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      child: Center(
        child: Text(
          'No tasks yet. Create your first task!',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }
}
