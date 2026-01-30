import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

// Core Constants & Providers
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/providers/collaboration_providers.dart'; 

// Data Layer
import '../../../data/models/enums.dart';
import '../../../data/database/database.dart'; 

// UI Features
import '../../notifications/presentation/notification_screen.dart';
import 'settings_screen.dart';
import 'widgets/summary_card.dart';
import 'widgets/dashboard_empty_state.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/quick_add_task_sheet.dart';

// =========================================================
// ✅ DATABASE PROVIDER (Place this in a central provider file)
// =========================================================
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// ✅ ALL PROJECTS PROVIDER (Uses the corrected databaseProvider)
final allProjectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.select(db.projects).get();
});

// =========================================================
// 🚀 DASHBOARD SCREEN (Full Corrected Code)
// =========================================================
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final projectsAsync = ref.watch(allProjectsProvider); 

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final completed = tasks.where((t) => t.status == TaskStatus.done.name).length;
    final pending = tasks.where((t) => t.status != TaskStatus.done.name).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD), 
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildPremiumAppBar(context, unreadCount),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('Overview', null, isDark),
                const SizedBox(height: 16),
                _buildStatCards(tasks.length, pending, completed),

                const SizedBox(height: 32),
                _buildSectionHeader('Active Projects', () => _showQuickProjectDialog(context, ref), isDark),
                const SizedBox(height: 16),
                _buildHorizontalProjectList(projectsAsync, isDark),

                const SizedBox(height: 32),
                _buildSectionHeader('Quick Actions', null, isDark),
                const SizedBox(height: 16),
                _buildQuickActionRow(context, isDark),

                const SizedBox(height: 32),
                _buildSectionHeader('Recent Tasks', () => context.push(AppRoutes.tasks), isDark),
                const SizedBox(height: 16),
                _buildTaskList(tasks, isDark),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context, isDark),
    );
  }

  // --- UI COMPONENT METHODS ---

  Widget _buildPremiumAppBar(BuildContext context, int unreadCount) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 140,
      stretch: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text('My Workspace', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
        background: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
      ),
      actions: [
        _buildNotificationButton(context, unreadCount),
        IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildStatCards(int total, int pending, int completed) {
    return Row(
      children: [
        _premiumStatCard('Total', total, Icons.grid_view_rounded, AppColors.primaryGradient),
        const SizedBox(width: 12),
        _premiumStatCard('Pending', pending, Icons.bolt_rounded, AppColors.upcomingGradient),
        const SizedBox(width: 12),
        _premiumStatCard('Done', completed, Icons.done_all_rounded, AppColors.completedGradient),
      ],
    );
  }

  Widget _buildHorizontalProjectList(AsyncValue<List<Project>> projects, bool isDark) {
    return SizedBox(
      height: 130,
      child: projects.when(
        data: (list) => list.isEmpty 
          ? const Center(child: Text("No projects found"))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              itemBuilder: (context, index) => _projectCard(context, list[index], isDark),
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Text("Error: $err"),
      ),
    );
  }

  Widget _projectCard(BuildContext context, Project project, bool isDark) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: InkWell(
        onTap: () => context.push('/projects/${project.id}'),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.folder_copy_rounded, color: AppColors.primary, size: 28),
              Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, bool isDark) {
    if (tasks.isEmpty) return const DashboardEmptyState();
    return Column(
      children: tasks.take(5).map((task) => _buildTaskItem(task, isDark)).toList(),
    );
  }

  Widget _buildTaskItem(Task task, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(task.title, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _premiumStatCard(String title, int value, IconData icon, LinearGradient gradient) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 12),
            Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onAction, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        if (onAction != null) TextButton(onPressed: onAction, child: const Text('Add New')),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context, int count) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.white), onPressed: () => context.push(AppRoutes.notifications)),
        if (count > 0)
          Positioned(right: 8, top: 10, child: CircleAvatar(radius: 8, backgroundColor: Colors.red, child: Text(count.toString(), style: const TextStyle(fontSize: 10, color: Colors.white)))),
      ],
    );
  }

  Widget _buildQuickActionRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(child: _actionButton(context, 'All Tasks', Icons.list, AppColors.primary, AppRoutes.tasks)),
        const SizedBox(width: 12),
        Expanded(child: _actionButton(context, 'Calendar', Icons.calendar_month, Colors.orange, AppRoutes.tasks)),
      ],
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon, Color color, String route) {
    return ElevatedButton.icon(
      onPressed: () => context.push(route),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.1), foregroundColor: color, elevation: 0),
    );
  }

  void _showQuickAddSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const QuickAddTaskSheet());
  }

  Widget _buildFAB(BuildContext context, bool isDark) {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickAddSheet(context, isDark),
      label: const Text('Quick Add', style: TextStyle(color: Colors.white)),
      icon: const Icon(Icons.add, color: Colors.white),
      backgroundColor: AppColors.primary,
    );
  }

  void _showQuickProjectDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Project"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Project Name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              final db = ref.read(databaseProvider);
              await db.into(db.projects).insert(ProjectsCompanion.insert(name: controller.text, createdAt: drift.Value(DateTime.now())));
              ref.invalidate(allProjectsProvider);
              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _openFilter(BuildContext context) {
    openFilterBottomSheet(context: context, allTags: const [], statusFilters: {}, priorityFilters: {}, tagFilters: {}, dueBucket: null, sort: null, onApply: (_, __, ___, ____, _____) {});
  }
}