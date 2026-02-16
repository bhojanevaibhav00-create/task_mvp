import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:task_mvp/data/database/database.dart' as db;
import 'package:task_mvp/features/tasks/presentation/task_detail_screen.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/providers/project_providers.dart';
import 'package:task_mvp/data/database/database.dart'; // ✅ Import for Task type
import 'package:task_mvp/data/models/enums.dart';
import 'package:task_mvp/features/tasks/presentation/task_create_edit_screen.dart';

import 'widgets/dashboard_empty_state.dart';
import 'package:task_mvp/features/tasks/presentation/widgets/quick_add_task_sheet.dart';
import 'package:task_mvp/features/dashboard/settings/presentation/screens/settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watches the providers to ensure the UI rebuilds on any data change
    final tasks = ref.watch(tasksProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final projectsAsync = ref.watch(allProjectsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final completed = tasks.where((t) => t.status == 'done').length;
    final pending = tasks.where((t) => t.status != 'done').length;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.scaffoldDark
          : const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 4,
        highlightElevation: 8,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        label: const Text(
          'Quick Add',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        onPressed: () => _openQuickAdd(context),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _premiumAppBar(context, unread, isDark),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionHeader('Overview', Icons.analytics_outlined, isDark),
                const SizedBox(height: 16),
                _statsRow(completed, pending, tasks.length),
                const SizedBox(height: 32),
                _sectionHeader(
                  'Projects',
                  Icons.folder_special_outlined,
                  isDark,
                ),
                const SizedBox(height: 12),
                _createProjectButton(context),
                const SizedBox(height: 16),
                // ✅ The reactive projects list
                _projects(projectsAsync, isDark, context),
                const SizedBox(height: 32),
                _sectionHeader('Quick Actions', Icons.bolt_rounded, isDark),
                const SizedBox(height: 16),
                _quickActions(context, isDark),
                const SizedBox(height: 32),
                _sectionHeader('Recent Tasks', Icons.history_rounded, isDark),
                const SizedBox(height: 16),
                _recentTasks(context, ref, tasks, isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ================= PREMIUM APP BAR =================
  Widget _premiumAppBar(BuildContext context, int unread, bool isDark) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 160,
      stretch: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        titlePadding: const EdgeInsets.only(left: 20, bottom: 18),
        title: const Text(
          'My Workspace',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            Positioned(
              top: -50,
              right: -50,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: Colors.white.withOpacity(0.05),
              ),
            ),
          ],
        ),
      ),
      actions: [
        _appBarAction(
          icon: Icons.notifications_none_rounded,
          count: unread,
          onTap: () => context.push(AppRoutes.notifications),
        ),
        _appBarAction(
          icon: Icons.settings_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _appBarAction({
    required IconData icon,
    int count = 0,
    required VoidCallback onTap,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white, size: 26),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // ================= SECTION HEADER =================
  Widget _sectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary.withOpacity(0.8)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ================= STATS =================
  Widget _statsRow(int done, int pending, int total) {
    return Row(
      children: [
        _statCard(
          'Total',
          total,
          Icons.grid_view_rounded,
          AppColors.primaryGradient,
        ),
        const SizedBox(width: 12),
        _statCard(
          'Pending',
          pending,
          Icons.auto_awesome_rounded,
          AppColors.upcomingGradient,
        ),
        const SizedBox(width: 12),
        _statCard(
          'Done',
          done,
          Icons.task_alt_rounded,
          AppColors.completedGradient,
        ),
      ],
    );
  }

  Widget _statCard(String label, int value, IconData icon, Gradient gradient) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CREATE PROJECT =================
  Widget _createProjectButton(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AppRoutes.createProject),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'New Project',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= PROJECTS (REACTIVE) =================
  Widget _projects(AsyncValue projects, bool isDark, BuildContext context) {
    return SizedBox(
      height: 150,
      child: projects.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(
          child: Text(
            'Error loading projects',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'No active projects',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final project = list[i];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black45
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => context.push('/projects/${project.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.folder_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        const Spacer(),
                        Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
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
  Widget _quickActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            'Task List',
            Icons.list_alt_rounded,
            () => context.push(AppRoutes.tasks),
            isDark,
            primary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            'Schedule',
            Icons.calendar_today_rounded,
            () {},
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    bool isDark, {
    bool primary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: primary
                ? AppColors.primary
                : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : AppColors.primary.withOpacity(0.08)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: primary ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: primary ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 /// ✅ Helper function to build the interactive checkbox icon
Widget _buildTaskLeading(WidgetRef ref, db.Task t, bool isDone) {
  return InkWell(
    onTap: () {
      final newStatus = isDone
          ? TaskStatus.todo.name
          : TaskStatus.done.name;
      ref
          .read(tasksProvider.notifier)
          .updateTask(t.copyWith(status: drift.Value(newStatus)));
    },
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDone
            ? Colors.green.withOpacity(0.1)
            : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: isDone ? Colors.green : AppColors.primary,
        size: 22,
      ),
    ),
  );
}

/// ✅ Helper function to open Detail Screen instead of Edit
void _openTaskDetail(BuildContext context, db.Task task) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TaskDetailScreen(task: task),
    ),
  );
}

Widget _recentTasks(
  BuildContext context,
  WidgetRef ref,
  List<db.Task> tasks,
  bool isDark,
) {
  if (tasks.isEmpty) return const DashboardEmptyState();

  return Column(
    children: tasks.take(5).map((t) {
      final isDone = t.status == TaskStatus.done.name;
      
      // ✅ Sprint 9 Task 1B: Watch subtasks for progress calculation
      final subtasksAsync = ref.watch(subtasksProvider(t.id));

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          // ✅ Sprint 9 UX Upgrade: Navigate to Detail Screen
          onTap: () => _openTaskDetail(context, t), 
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _buildTaskLeading(ref, t, isDone), // ✅ FIXED: Function now defined
          title: Text(
            t.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                t.status ?? 'In Progress',
                style: TextStyle(
                  fontSize: 12, 
                  color: isDark ? Colors.white38 : Colors.black38
                ),
              ),
              
              // ✅ Sprint 9 Task 1B: Mini Progress Bar
              subtasksAsync.when(
                data: (list) {
                  if (list.isEmpty) return const SizedBox.shrink();
                  final completed = list.where((s) => s.isCompleted).length;
                  final progress = completed / list.length;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress == 1.0 ? Colors.green : AppColors.primary
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded, 
            size: 14, 
            color: Colors.grey
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
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickAddTaskSheet(),
    );
  }

  void _openEditTask(BuildContext context, WidgetRef ref, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskCreateEditScreen(task: task)),
    ).then((changed) {
      if (changed == true) ref.read(tasksProvider.notifier).loadTasks();
    });
  }
}
