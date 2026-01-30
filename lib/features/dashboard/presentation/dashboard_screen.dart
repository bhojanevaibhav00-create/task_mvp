import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

import 'package:task_mvp/core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/providers/task_providers.dart' hide databaseProvider;
import '../../../core/providers/notification_providers.dart';
import '../../../core/providers/collaboration_providers.dart'; 
import '../../../data/models/enums.dart';
import '../../../data/database/database.dart'; 
import '../../notifications/presentation/notification_screen.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/filter_bottom_sheet.dart';

// ✅ Added this to fix the 'allProjectsProvider' error
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

    final completed = tasks.where((t) => t.status == TaskStatus.done.name).length;
    final pending = tasks.where((t) => t.status != TaskStatus.done.name).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), 
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
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
                    onApply: (status, priority, tags, due, sort) {},
                  );
                },
              ),
              const SizedBox(width: 12),
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

                _buildSectionHeader('Active Projects', () => _showQuickProjectDialog(context, ref)),
                const SizedBox(height: 16),
                _buildHorizontalProjectList(projectsAsync),

                const SizedBox(height: 32),

                _buildSectionHeader('Quick Actions', null),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(context, 'View Tasks', Icons.format_list_bulleted_rounded, Colors.white, AppColors.primary, AppRoutes.tasks),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButton(context, 'Add New', Icons.add_rounded, AppColors.primary, Colors.white, AppRoutes.tasks),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                _buildSectionHeader('Recent Tasks', () => context.push(AppRoutes.tasks)),
                const SizedBox(height: 16),

                if (tasks.isEmpty)
                  _emptyState()
                else
                  ...tasks.take(5).map((task) => _buildTaskItem(context, task)),
                
                const SizedBox(height: 20),
                const Divider(color: Colors.transparent),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.tasks),
        backgroundColor: AppColors.primary,
        elevation: 8,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text('New Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHorizontalProjectList(AsyncValue<List<Project>> projects) {
    return SizedBox(
      height: 130,
      child: projects.when(
        data: (list) => list.isEmpty 
          ? _buildSmallEmptyState("No active projects found")
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final p = list[index];
                // ✅ Pass context and Project object to the card
                return _projectCard(context, p, "Active", Icons.folder_copy_rounded);
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Text("Error: $err", style: const TextStyle(fontSize: 10)),
      ),
    );
  }

  // ✅ UPDATED: Project Card is now clickable and routes to Detail Screen
  Widget _projectCard(BuildContext context, Project project, String status, IconData icon) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            // ✅ Navigate to the Project Detail Screen using the ID
            // Make sure your GoRouter or Navigator matches this path
            context.push('/projects/${project.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: AppColors.primary, size: 28),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis, 
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(status, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
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
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDone ? Colors.green.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isDone ? Colors.green : AppColors.primary,
            size: 22,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 15, 
            fontWeight: FontWeight.w600, 
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.grey : const Color(0xFF111827)
          ),
        ),
        trailing: task.assigneeId != null 
          ? CircleAvatar(
              radius: 12,
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.person, size: 14, color: Colors.blue),
            )
          : const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
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
        boxShadow: bgColor != Colors.white ? [BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
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

  Widget _premiumStatCard(String title, int value, IconData icon, LinearGradient gradient) {
    return Expanded(
      child: Container(
        height: 115,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                Text(title, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text('Add New', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context, int count) {
    return Center(
      child: Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          if (count > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSmallEmptyState(String text) {
    return Center(child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13)));
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 40, color: Colors.orange.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text('No tasks found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showQuickProjectDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Create New Project", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Project Name", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              final db = ref.read(databaseProvider);
              await db.into(db.projects).insert(ProjectsCompanion.insert(
                name: controller.text,
                createdAt: drift.Value(DateTime.now()),
              ));
              ref.invalidate(allProjectsProvider); 
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}