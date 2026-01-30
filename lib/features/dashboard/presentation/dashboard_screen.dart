import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

// Core
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/notification_providers.dart';

// Data
import '../../../data/models/enums.dart';
import '../../../data/database/database.dart';

// UI
import '../../notifications/presentation/notification_screen.dart';
import 'settings_screen.dart';
import 'widgets/dashboard_empty_state.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/quick_add_task_sheet.dart';

/// =========================================================
/// DATABASE PROVIDER (already used by your app)
/// =========================================================
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final allProjectsProvider =
FutureProvider.autoDispose<List<Project>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.select(db.projects).get();
});

/// =========================================================
/// DASHBOARD SCREEN
/// =========================================================
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final projectsAsync = ref.watch(allProjectsProvider);

    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    final completed =
        tasks
            .where((t) => t.status == TaskStatus.done.name)
            .length;
    final pending =
        tasks
            .where((t) => t.status != TaskStatus.done.name)
            .length;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, unreadCount),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _sectionHeader('Overview', null, isDark),
                  const SizedBox(height: 16),
                  _statsRow(tasks.length, pending, completed),

                  const SizedBox(height: 32),
                  _sectionHeader(
                    'Active Projects',
                        () => _showAddProject(context, ref),
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _projectList(projectsAsync, isDark),

                  const SizedBox(height: 32),
                  _sectionHeader('Quick Actions', null, isDark),
                  const SizedBox(height: 16),
                  _quickActions(context),

                  const SizedBox(height: 32),
                  _sectionHeader(
                    'Recent Tasks',
                        () => context.push(AppRoutes.tasks),
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _recentTasks(tasks, isDark),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openQuickAdd(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Quick Add',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // =========================================================
  // APP BAR
  // =========================================================
  Widget _buildAppBar(BuildContext context, int unread) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 140,
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
              icon: const Icon(Icons.notifications_none, color: Colors.white),
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
                      fontSize: 10,
                      color: Colors.white,
                    ),
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
              MaterialPageRoute(builder: (_) => SettingsScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // =========================================================
  // SECTION HEADER
  // =========================================================
  Widget _sectionHeader(String title,
      VoidCallback? action,
      bool isDark,) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: action,
            child: const Text(
              'Add New',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  // =========================================================
  // STATS
  // =========================================================
  Widget _statsRow(int total, int pending, int completed) {
    return Row(
      children: [
        _statCard('Total', total, Icons.grid_view, AppColors.primaryGradient),
        const SizedBox(width: 12),
        _statCard('Pending', pending, Icons.bolt, AppColors.upcomingGradient),
        const SizedBox(width: 12),
        _statCard(
            'Done', completed, Icons.done_all, AppColors.completedGradient),
      ],
    );
  }

  Widget _statCard(String label,
      int value,
      IconData icon,
      LinearGradient gradient,) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 14),
            Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PROJECTS
  // =========================================================
  Widget _projectList(AsyncValue<List<Project>> projects, bool isDark) {
    return SizedBox(
      height: 130,
      child: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No projects found'));
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            itemBuilder: (_, i) => _projectCard(list[i], isDark),
          );
        },
      ),
    );
  }

  Widget _projectCard(Project p, bool isDark) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.folder, color: AppColors.primary),
              Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // QUICK ACTIONS
  // =========================================================
  Widget _quickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionBtn(
            context,
            'All Tasks',
            Icons.list_alt,
            AppColors.primary,
            AppRoutes.tasks,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _actionBtn(
            context,
            'Calendar',
            Icons.calendar_month,
            Colors.orange,
            AppRoutes.tasks,
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(BuildContext context,
      String label,
      IconData icon,
      Color color,
      String route,) {
    return ElevatedButton.icon(
      onPressed: () => context.push(route),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.12),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // =========================================================
  // RECENT TASKS
  // =========================================================
  Widget _recentTasks(List<Task> tasks, bool isDark) {
    if (tasks.isEmpty) {
      return const DashboardEmptyState();
    }
    return Column(
      children: tasks.take(5).map((t) => _taskTile(t, isDark)).toList(),
    );
  }

  Widget _taskTile(Task t, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(
          t.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  // =========================================================
  // HELPERS
  // =========================================================
  void _openQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const QuickAddTaskSheet(),
    );
  }

  void _showAddProject(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text('New Project'),
            content: TextField(controller: controller),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.isEmpty) return;
                  final db = ref.read(databaseProvider);
                  await db.into(db.projects).insert(
                    ProjectsCompanion.insert(
                      name: controller.text,
                      createdAt: drift.Value(DateTime.now()),
                    ),
                  );
                  ref.invalidate(allProjectsProvider);
                  Navigator.pop(context);
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }
}