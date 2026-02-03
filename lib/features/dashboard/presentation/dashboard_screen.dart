import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

// Core Constants & Providers
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/notification_providers.dart' hide databaseProvider;
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

// ✅ FIXED: Changed to .watch() for real-time UI updates when projects are deleted or added
final allProjectsProvider = StreamProvider.autoDispose<List<Project>>((ref) {
  final db = ref.watch(databaseProvider); 
  // We use watch() to ensure the stream closes and re-opens when data changes
  return db.select(db.projects).watch();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final projectsAsync = ref.watch(allProjectsProvider); 

    const backgroundColor = Color(0xFFF8F9FD); 
    const cardColor = Colors.white;
    const primaryTextColor = Color(0xFF1A1C1E);

    final completed = tasks.where((t) => t.status == TaskStatus.done.name).length;
    final pending = tasks.where((t) => t.status != TaskStatus.done.name).length;

    return Scaffold(
      backgroundColor: backgroundColor, 
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildPremiumAppBar(context, unreadCount),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('Overview', null, primaryTextColor),
                const SizedBox(height: 16),
                _buildStatCards(tasks.length, pending, completed),

                const SizedBox(height: 32),
                _buildSectionHeader('Active Projects', () => _showQuickProjectDialog(context, ref), primaryTextColor),
                const SizedBox(height: 16),
                _buildHorizontalProjectList(projectsAsync, cardColor, primaryTextColor),

                const SizedBox(height: 32),
                _buildSectionHeader('Quick Actions', null, primaryTextColor),
                const SizedBox(height: 16),
                _buildQuickActionRow(context),

                const SizedBox(height: 32),
                _buildSectionHeader('Recent Tasks', () => context.push(AppRoutes.tasks), primaryTextColor),
                const SizedBox(height: 16),
                _buildTaskList(context, tasks, cardColor, primaryTextColor),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildPremiumAppBar(BuildContext context, int unreadCount) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 140,
      stretch: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text('My Workspace', 
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
        background: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
      ),
      actions: [
        _buildNotificationButton(context, unreadCount),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white), 
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()))
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildStatCards(int total, int pending, int completed) {
    return Row(
      children: [
        _statCard('Total', total, Icons.grid_view_rounded, AppColors.primary),
        const SizedBox(width: 12),
        _statCard('Pending', pending, Icons.bolt_rounded, Colors.orange),
        const SizedBox(width: 12),
        _statCard('Done', completed, Icons.done_all_rounded, Colors.green),
      ],
    );
  }

  Widget _statCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black38)),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalProjectList(AsyncValue<List<Project>> projects, Color cardColor, Color textColor) {
    return SizedBox(
      height: 110,
      child: projects.when(
        data: (list) {
          // ✅ FIXED: Filter out any empty/broken projects that might show up as "General"
          final validProjects = list.where((p) => p.name.isNotEmpty && p.name != "General").toList();
          
          if (validProjects.isEmpty) {
            return _emptyContentCard("No projects found", Icons.folder_open);
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: validProjects.length,
            itemBuilder: (context, index) => _projectCard(context, validProjects[index], cardColor, textColor),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error loading projects")),
      ),
    );
  }

  Widget _projectCard(BuildContext context, Project project, Color cardColor, Color textColor) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/projects/${project.id}'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFEEF2FF), 
                  child: Icon(Icons.work_outline, color: AppColors.primary, size: 18)
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    project.name, 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor), 
                    overflow: TextOverflow.ellipsis
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, List<Task> tasks, Color cardColor, Color textColor) {
    if (tasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.03)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFFF0F4FF), shape: BoxShape.circle),
              child: const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 20),
            const Text("No tasks for today", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1C1E))),
            const SizedBox(height: 8),
            const Text("Your schedule looks clear.", 
              textAlign: TextAlign.center, style: TextStyle(color: Colors.black38, fontSize: 14)),
          ],
        ),
      );
    }
    return Column(
      children: tasks.take(5).map((task) => _buildTaskItem(context, task, cardColor, textColor)).toList(),
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        title: Text(task.title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black12),
        onTap: () => context.push('/tasks/${task.id}'),
      ),
    );
  }

  Widget _emptyContentCard(String message, IconData icon) {
    return Container(
      width: 180,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black12, size: 24),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.black26, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onAction, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
        if (onAction != null) 
          TextButton(onPressed: onAction, child: const Text('Add New', style: TextStyle(color: AppColors.primary))),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context, int count) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26), 
          onPressed: () => context.push(AppRoutes.notifications)
        ),
        if (count > 0)
          Positioned(
            right: 8, top: 10, 
            child: CircleAvatar(
              radius: 8, 
              backgroundColor: Colors.red, 
              child: Text(count.toString(), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))
            )
          ),
      ],
    );
  }

  Widget _buildQuickActionRow(BuildContext context) {
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
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.06), 
        foregroundColor: color, 
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => showModalBottomSheet(
        context: context, 
        isScrollControlled: true, 
        backgroundColor: Colors.transparent, 
        builder: (_) => const QuickAddTaskSheet()
      ),
      label: const Text('Quick Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      icon: const Icon(Icons.bolt_rounded, color: Colors.white),
      backgroundColor: AppColors.primary,
    );
  }

  void _showQuickProjectDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("New Project", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Color(0xFF1A1C1E)),
          decoration: InputDecoration(
            hintText: "Enter project name",
            hintStyle: const TextStyle(color: Colors.black26),
            filled: true,
            fillColor: const Color(0xFFF8F9FD),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final db = ref.read(databaseProvider);
              await db.into(db.projects).insert(ProjectsCompanion.insert(
                name: controller.text.trim(), 
                createdAt: drift.Value(DateTime.now())
              ));
              // ✅ REFRESH THE UI
              ref.invalidate(allProjectsProvider);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, 
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}