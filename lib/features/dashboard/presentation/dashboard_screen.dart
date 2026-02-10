import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/providers/project_providers.dart';

import 'settings_screen.dart';
import 'widgets/dashboard_empty_state.dart';
import 'widgets/quick_add_task_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final projectsAsync = ref.watch(allProjectsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final completed = tasks.where((t) => t.status == 'done').length;
    final pending = tasks.where((t) => t.status != 'done').length;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : const Color(0xFFF6F7FB),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Quick Add',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () => _openQuickAdd(context),
      ),

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _premiumAppBar(context, unread),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _sectionTitle('Overview', isDark),
                  const SizedBox(height: 16),
                  _statsRow(tasks.length, pending, completed),

                  const SizedBox(height: 32),
                  _sectionTitle('Projects', isDark),
                  const SizedBox(height: 12),

                  // ✅ CREATE PROJECT BUTTON (RESTORED)
                  _createProjectButton(context),

                  const SizedBox(height: 16),
                  _projects(projectsAsync, isDark, context),

                  const SizedBox(height: 32),
                  _sectionTitle('Quick Actions', isDark),
                  const SizedBox(height: 16),
                  _quickActions(context),

                  const SizedBox(height: 32),
                  _sectionTitle('Recent Tasks', isDark),
                  const SizedBox(height: 16),
                  _recentTasks(tasks, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= APP BAR =================
  Widget _premiumAppBar(BuildContext context, int unread) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 150,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          'My Workspace',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon:
              const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () =>
                  context.push(AppRoutes.notifications),
            ),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 10,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.red,
                  child: Text(
                    unread.toString(),
                    style: const TextStyle(
                        fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SettingsScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ================= SECTION TITLE =================
  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  // ================= STATS =================
  Widget _statsRow(int total, int pending, int done) {
    return Row(
      children: [
        _statCard(
            'Total', total, Icons.grid_view, AppColors.primaryGradient),
        const SizedBox(width: 12),
        _statCard(
            'Pending', pending, Icons.bolt, AppColors.upcomingGradient),
        const SizedBox(width: 12),
        _statCard(
            'Done', done, Icons.done_all, AppColors.completedGradient),
      ],
    );
  }

  Widget _statCard(
      String label, int value, IconData icon, Gradient gradient) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 14),
            Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CREATE PROJECT =================
  Widget _createProjectButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.createProject),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Create New Project',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= PROJECTS =================
  Widget _projects(
      AsyncValue projects, bool isDark, BuildContext context) {
    return SizedBox(
      height: 140,
      child: projects.when(
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No projects yet'));
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            itemBuilder: (_, i) {
              final project = list[i];
              return GestureDetector(
                onTap: () =>
                    context.push('/projects/${project.id}'),
                child: Container(
                  width: 170,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                    isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.folder,
                          color: AppColors.primary),
                      const Spacer(),
                      Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ================= QUICK ACTIONS =================
  Widget _quickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            'View Tasks',
            Icons.view_list,
                () => context.push(AppRoutes.tasks),
            primary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            'Calendar',
            Icons.calendar_month,
                () {},
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
      String label,
      IconData icon,
      VoidCallback onTap, {
        bool primary = false,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: primary
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color:
                primary ? Colors.white : AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: primary
                    ? Colors.white
                    : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= RECENT TASKS =================
  Widget _recentTasks(List tasks, bool isDark) {
    if (tasks.isEmpty) return const DashboardEmptyState();

    return Column(
      children: tasks.take(5).map((t) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color:
            isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            title: Text(
              t.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _openQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const QuickAddTaskSheet(),
    );
  }
}