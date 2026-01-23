import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:task_mvp/core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/notification_providers.dart';
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

    final completed = tasks.where((t) => t.status == TaskStatus.done.name).length;
    final pending = tasks.where((t) => t.status != TaskStatus.done.name).length;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), 
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ================= PREMIUM APP BAR =================
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            stretch: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'My Workspace',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
                  Positioned(
                    top: -30,
                    right: -30,
                    child: CircleAvatar(
                      radius: 80, 
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              _buildNotificationButton(context, unreadCount),
              // Filter button from remote version
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
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
                      // Filter logic
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('Overview', null),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _premiumStatCard('Total', tasks.length, Icons.grid_view_rounded, AppColors.primaryGradient),
                    const SizedBox(width: 12),
                    _premiumStatCard('Pending', pending, Icons.bolt_rounded, AppColors.upcomingGradient),
                    const SizedBox(width: 12),
                    _premiumStatCard('Done', completed, Icons.done_all_rounded, AppColors.completedGradient),
                  ],
                ),

                const SizedBox(height: 32),

                _buildSectionHeader('Quick Actions', null),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        context, 
                        'View Tasks', 
                        Icons.format_list_bulleted_rounded,
                        Colors.white, 
                        AppColors.primary,
                        AppRoutes.tasks,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButton(
                        context, 
                        'Add New', 
                        Icons.add_rounded, 
                        AppColors.primary, 
                        Colors.white,
                        AppRoutes.tasks, 
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                _buildSectionHeader('Recent Tasks', () => context.push(AppRoutes.tasks)),
                const SizedBox(height: 16),

                if (tasks.isEmpty)
                  _emptyState()
                else
                  ...tasks.take(4).map((task) => _buildTaskItem(context, task)),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.tasks),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text('New Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w800, 
            color: Color(0xFF1A1C1E),
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            child: const Text('See All', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _premiumStatCard(String title, int value, IconData icon, LinearGradient gradient) {
    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, dynamic task) {
    final isDone = task.status == TaskStatus.done.name;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDone ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.done_all_rounded : Icons.timer_outlined,
            color: isDone ? Colors.green : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          task.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: () => context.push(AppRoutes.tasks),
      ),
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon, Color textColor, Color bgColor, String route) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: bgColor != Colors.white 
          ? [BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
          : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(route),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, int count) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          ),
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_motion_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('All caught up!', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}