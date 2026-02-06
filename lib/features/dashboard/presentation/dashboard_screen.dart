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
import '../../../data/repositories/task_repository.dart';

// UI Features
import '../../notifications/presentation/notification_screen.dart';
import 'settings_screen.dart';
import 'widgets/summary_card.dart';
import 'widgets/dashboard_empty_state.dart';
import 'widgets/quick_add_task_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 WATCHING LIVE STREAMS
    final tasksAsync = ref.watch(filteredTasksProvider); 
    final projectsAsync = ref.watch(allProjectsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    // ✅ PREMIUM WHITE THEME CONSTANTS
    const backgroundColor = Color(0xFFF8F9FD); 
    const primaryTextColor = Color(0xFF1A1C1E);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                // 1. STATS OVERVIEW
                _buildSectionHeader(
                  title: 'Overview', 
                  textColor: primaryTextColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                tasksAsync.when(
                  data: (wrappers) => _buildStatCards(wrappers.map((w) => w.task).toList()),
                  loading: () => _buildLoadingShimmer(height: 100),
                  error: (e, __) => _buildErrorWidget(e.toString()),
                ),

                const SizedBox(height: 32),
                
                // 2. ACTIVE PROJECTS
                _buildSectionHeader(
                  title: 'Active Projects', 
                  textColor: primaryTextColor,
                  isDark: isDark,
                  onAction: () => _showQuickProjectDialog(context, ref),
                ),
                const SizedBox(height: 16),
                _buildHorizontalProjectList(projectsAsync, primaryTextColor, isDark),

                const SizedBox(height: 32),
                
                // 3. QUICK ACTIONS
                _buildSectionHeader(
                  title: 'Quick Actions', 
                  textColor: primaryTextColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildQuickActionRow(context),

                const SizedBox(height: 32),
                
                // 4. RECENT TASKS
                _buildSectionHeader(
                  title: 'Recent Tasks', 
                  textColor: primaryTextColor,
                  isDark: isDark,
                  onAction: () => context.push(AppRoutes.tasks),
                  actionLabel: 'View All',
                ),
                const SizedBox(height: 16),
                tasksAsync.when(
                  data: (wrappers) => _buildTaskList(context, wrappers, primaryTextColor, isDark),
                  loading: () => _buildLoadingShimmer(height: 200),
                  error: (e, __) => _buildErrorWidget(e.toString()),
                ),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  // --- APP BAR COMPONENT ---

  Widget _buildPremiumAppBar(BuildContext context, int unreadCount) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 140,
      stretch: true,
      backgroundColor: AppColors.primary,
      leadingWidth: 72, 
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16), 
        title: const Text(
          'My Workspace', 
          style: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.w900, 
            color: Colors.white,
            letterSpacing: -0.5,
          )
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      actions: [
        _buildNotificationButton(context, unreadCount),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white), 
          onPressed: () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const SettingsScreen())
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  // --- STATS COMPONENTS ---

  Widget _buildStatCards(List<Task> tasks) {
    final completed = tasks.where((t) => t.status?.toLowerCase() == 'done').length;
    final pending = tasks.length - completed;

    return Row(
      children: [
        _statCard('Total', tasks.length, Icons.grid_view_rounded, AppColors.primary),
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
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), 
              blurRadius: 12, 
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 14),
            Text(
              '$count', 
              style: const TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.w900, 
                color: Color(0xFF1A1C1E)
              )
            ),
            Text(
              label, 
              style: const TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.w600)
            ),
          ],
        ),
      ),
    );
  }

  // --- PROJECT COMPONENTS ---

  Widget _buildHorizontalProjectList(AsyncValue<List<Project>> projects, Color textColor, bool isDark) {
    return SizedBox(
      height: 120,
      child: projects.when(
        data: (list) {
          final validProjects = list.where((p) => p.name.isNotEmpty && p.name != "General").toList();
          if (validProjects.isEmpty) return _emptyContentCard("No projects found", Icons.folder_open_outlined);

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: validProjects.length,
            itemBuilder: (context, index) => _projectCard(context, validProjects[index], textColor, isDark),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (err, _) => _buildErrorWidget("Projects failed"),
      ),
    );
  }

  Widget _projectCard(BuildContext context, Project project, Color textColor, bool isDark) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/projects/${project.id}'),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 18),
                ),
                const Spacer(),
                Text(
                  project.name, 
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textColor), 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TASK LIST COMPONENTS ---

  Widget _buildTaskList(BuildContext context, List<TaskWithAssignee> wrappers, Color textColor, bool isDark) {
    // ✅ FIXED: Using DashboardEmptyState to remove the black box
    if (wrappers.isEmpty) return const DashboardEmptyState();
    
    return Column(
      children: wrappers.take(5).map((wrapper) => _buildTaskItem(context, wrapper, textColor, isDark)).toList(),
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskWithAssignee wrapper, Color textColor, bool isDark) {
    final task = wrapper.task;
    final assigneeName = wrapper.assignee?.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 15, 
            offset: const Offset(0, 6)
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          task.title, 
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 15)
        ),
        subtitle: assigneeName != null 
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 12, color: Colors.black38),
                    const SizedBox(width: 4),
                    Text(assigneeName, style: const TextStyle(fontSize: 12, color: Colors.black38)),
                  ],
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black12),
        onTap: () => context.push('/tasks/${task.id}'),
      ),
    );
  }

  // --- SHARED UI HELPERS ---

  Widget _buildSectionHeader({
    required String title, 
    required Color textColor, 
    required bool isDark,
    VoidCallback? onAction,
    String actionLabel = 'Add New'
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title, 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)
        ),
        if (onAction != null) 
          TextButton(
            onPressed: onAction, 
            child: Text(
              actionLabel, 
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)
            )
          ),
      ],
    );
  }

  Widget _buildQuickActionRow(BuildContext context) {
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
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.08), 
        foregroundColor: color, 
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))
      ),
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
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text(
                count.toString(), 
                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
          ),
      ],
    );
  }

  Widget _emptyContentCard(String message, IconData icon) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.03))
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black12, size: 28),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.black26, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
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
      label: const Text('Quick Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      backgroundColor: AppColors.primary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildLoadingShimmer({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(child: Text("Error: $error", style: const TextStyle(color: Colors.redAccent, fontSize: 12)));
  }

  void _showQuickProjectDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("New Project", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
        content: TextField(
          controller: controller,
          autofocus: true,
          // ✅ FIXED: Added visible text color for input
          style: const TextStyle(color: Color(0xFF1A1C1E), fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: "Enter project name",
            hintStyle: const TextStyle(color: Colors.black26),
            filled: true,
            fillColor: const Color(0xFFF8F9FD),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
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
              ref.invalidate(allProjectsProvider);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Create", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}