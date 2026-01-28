import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../data/models/enums.dart';

import '../../notifications/presentation/notification_screen.dart';
import 'settings_screen.dart';

import 'widgets/summary_card.dart';
import 'widgets/dashboard_empty_state.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/quick_add_task_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final completed =
        tasks.where((t) => t.status == TaskStatus.done.name).length;
    final pending =
        tasks.where((t) => t.status != TaskStatus.done.name).length;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,

      body: CustomScrollView(
        slivers: [
          // ================= APP BAR =================
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('My Workspace'),
              background: Container(
                decoration:
                const BoxDecoration(gradient: AppColors.primaryGradient),
              ),
            ),
            actions: [
              // Notifications
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
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

              // Filter
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  openFilterBottomSheet(
                    context: context,
                    allTags: const [],
                    statusFilters: {},
                    priorityFilters: {},
                    tagFilters: {},
                    dueBucket: null,
                    sort: null,
                    onApply: (_, __, ___, ____, _____) {},
                  );
                },
              ),

              // Settings
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>  SettingsScreen(),
                    ),
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
                // OVERVIEW
                Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    SummaryCard(
                      title: 'Total',
                      value: tasks.length.toString(),
                      icon: Icons.grid_view,
                      gradientColors: const [
                        Color(0xFF6366F1),
                        Color(0xFF4F46E5),
                      ],
                    ),
                    const SizedBox(width: 12),
                    SummaryCard(
                      title: 'Pending',
                      value: pending.toString(),
                      icon: Icons.schedule,
                      gradientColors: const [
                        Color(0xFF22C55E),
                        Color(0xFF16A34A),
                      ],
                    ),
                    const SizedBox(width: 12),
                    SummaryCard(
                      title: 'Done',
                      value: completed.toString(),
                      icon: Icons.check_circle,
                      gradientColors: const [
                        Color(0xFF64748B),
                        Color(0xFF475569),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // QUICK ACTIONS
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 12),

                // VIEW TASKS
                InkWell(
                  onTap: () => context.push(AppRoutes.tasks),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color:
                          AppColors.primary.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.view_list, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'View Tasks',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // QUICK ADD
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Task'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => const QuickAddTaskSheet(),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // RECENT TASKS
                Text(
                  'Recent Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 12),

                if (tasks.isEmpty)
                  const DashboardEmptyState()
                else
                  ...tasks.take(5).map(
                        (task) => Card(
                      color: isDark
                          ? AppColors.cardDark
                          : AppColors.cardLight,
                      child: ListTile(
                        title: Text(task.title),
                        trailing:
                        const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push(AppRoutes.tasks),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
