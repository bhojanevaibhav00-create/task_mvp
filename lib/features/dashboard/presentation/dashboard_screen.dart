import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/providers/collaboration_providers.dart'; 
import '../../../data/models/enums.dart';
import '../../../data/database/database.dart'; 
import '../../notifications/presentation/notification_screen.dart';
import 'settings_screen.dart';

import 'widgets/summary_card.dart';
import 'widgets/dashboard_empty_state.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/quick_add_task_sheet.dart';

// ✅ Global provider for project list
final allProjectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.select(db.projects).get();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final projectsAsync = ref.watch(allProjectsProvider); 

    // ✅ VAISHNAVI: Theme & Dark Mode Logic
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final completed = tasks.where((t) => t.status == TaskStatus.done.name).length;
    final pending = tasks.where((t) => t.status != TaskStatus.done.name).length;

    return Scaffold(
      // ✅ VAISHNAVI: Adaptive Background Color
      backgroundColor: isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD), 
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
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
                  Positioned(
                    top: -20,
                    right: -20,
                    child: CircleAvatar(
                      radius: 70, 
                      backgroundColor: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              _buildNotificationButton(context, unreadCount),
              // ✅ VAISHNAVI: Filter & Settings Buttons
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: () => _openFilter(context),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
              const SizedBox(width: 12),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ================= OVERVIEW =================
                _buildSectionHeader('Overview', null, isDark),
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

                // ================= VAIBHAV: PROJECTS =================
                _buildSectionHeader('Active Projects', () => _showQuickProjectDialog(context, ref), isDark),
                const SizedBox(height: 16),
                _buildHorizontalProjectList(projectsAsync, isDark),

                const SizedBox(height: 32),

                // ================= QUICK ACTIONS =================
                _buildSectionHeader('Quick Actions', null, isDark),
                const SizedBox(height: 16),
                _buildQuickActionRow(context, isDark),

                const SizedBox(height: 32),

                // ================= RECENT TASKS =================
                _buildSectionHeader('Recent Tasks', () => context.push(AppRoutes.tasks), isDark),
                const SizedBox(height: 16),
                if (tasks.isEmpty)
                  const DashboardEmptyState() // ✅ VAISHNAVI: Empty State Widget
                else
                  ...tasks.take(5).map((task) => _buildTaskItem(context, task, isDark)),
              ]),
            ),
          ),
        ],
      ),
      // ✅ VAISHNAVI: Quick Add Bottom Sheet Trigger
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickAddSheet(context, isDark),
        backgroundColor: AppColors.primary,
        elevation: 8,
        icon: const Icon(Icons.bolt_rounded, color: Colors.white),
        label: const Text('Quick Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- MERGED HELPER METHODS ---

  Widget _buildHorizontalProjectList(AsyncValue<List<Project>> projects, bool isDark) {
    return SizedBox(
      height: 130,
      child: projects.when(
        data: (list) => list.isEmpty 
          ? const Center(child: Text("No projects found", style: TextStyle(color: Colors.grey)))
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

  Widget _buildQuickActionRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(child: _actionButton(context, 'All Tasks', Icons.format_list_bulleted_rounded, AppColors.primary, AppRoutes.tasks)),
        const SizedBox(width: 12),
        Expanded(child: _actionButton(context, 'Calendar', Icons.calendar_today_rounded, Colors.orange, AppRoutes.tasks)),
      ],
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon, Color color, String route) {
    return ElevatedButton.icon(
      onPressed: () => context.push(route),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onAction, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1A1C1E))),
        if (onAction != null)
          TextButton(onPressed: onAction, child: const Text('Add New')),
      ],
    );
  }

  // ... (Include _premiumStatCard, _buildTaskItem, _buildNotificationButton and _showQuickProjectDialog here)
  
  void _showQuickAddSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const QuickAddTaskSheet(),
    );
  }

  void _openFilter(BuildContext context) {
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
  }
}