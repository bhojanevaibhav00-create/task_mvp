import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

// Core Constants & Providers
import 'package:task_mvp/core/constants/app_colors.dart';
import 'package:task_mvp/core/providers/task_providers.dart';
import 'package:task_mvp/core/providers/collaboration_providers.dart'; 
import 'package:task_mvp/features/projects/widgets/add_member_dialog.dart'; 
import 'package:task_mvp/features/tasks/presentation/widgets/task_card.dart'; 
import 'package:task_mvp/data/database/database.dart';
import 'package:task_mvp/data/models/enums.dart';
import 'package:task_mvp/data/repositories/task_repository.dart'; // ✅ KEEP: Required for TaskWithAssignee
import 'package:task_mvp/features/projects/presentation/project_members_screen.dart';

// Local state for project task sorting
final projectSortProvider = StateProvider.autoDispose<String>((ref) => 'date');

class ProjectDetailScreen extends ConsumerWidget {
  final int projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(allProjectsProvider);
    final repository = ref.watch(taskRepositoryProvider);
    final currentSort = ref.watch(projectSortProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return projectsAsync.when(
      data: (projects) {
        Project? project;
        try {
          project = projects.firstWhere((p) => p.id == projectId);
        } catch (_) {
          project = null;
        }

        if (project == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F9FD),
            body: Center(child: Text("Project not found or was deleted")),
          );
        }
        
        return Scaffold(
          backgroundColor: isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. PREMIUM MODERN APP BAR
              _buildModernAppBar(context, ref, project),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 2. MODERN EDITABLE DESCRIPTION
                    _buildPremiumDescription(context, ref, project, isDark),
                    const SizedBox(height: 24),
                    
                    // 3. PROGRESS TRACKER
                    _buildModernProgressHeader(ref),
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.list_alt_rounded, color: isDark ? Colors.white : const Color(0xFF1A1C1E), size: 22),
                            const SizedBox(width: 12),
                            Text(
                              "Project Tasks",
                              style: TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.w900, 
                                color: isDark ? Colors.white : const Color(0xFF1A1C1E)
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Sorted by ${currentSort == 'priority' ? 'Priority' : 'Date'}",
                          style: const TextStyle(fontSize: 10, color: Colors.black26, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
              
              // 4. DYNAMIC TASK LIST (With TaskWithAssignee Support)
              StreamBuilder<List<TaskWithAssignee>>(
                stream: repository.watchTasksWithAssignee(
                  projectId: projectId,
                  sortBy: currentSort == 'priority' ? 'priority_desc' : 'due_date_asc',
                ),
                builder: (context, snapshot) {
                  final wrappers = snapshot.data ?? [];

                  if (wrappers.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_late_outlined, color: Colors.grey.shade300, size: 60),
                            const SizedBox(height: 16),
                            const Text("No tasks found", style: TextStyle(color: Colors.black38)),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = wrappers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: TaskCard(
                              task: item.task,
                              assigneeName: item.assignee?.name, // ✅ FIXED: Pass member name to card
                              onTap: () => context.push('/tasks/${item.task.id}'),
                              onToggleDone: () => _toggleTaskStatus(ref, item.task),
                            ),
                          );
                        },
                        childCount: wrappers.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: _buildModernFAB(context),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Error: $e"))),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildModernAppBar(BuildContext context, WidgetRef ref, Project project) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: AppColors.primary,
      leadingWidth: 70, 
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
        title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
            ),
          ),
        ),
      ),
      leading: IconButton(
        padding: const EdgeInsets.only(left: 16),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => context.pop(),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort_rounded, color: Colors.white),
          onSelected: (value) => ref.read(projectSortProvider.notifier).state = value,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'date', child: Text("Sort by Date")),
            const PopupMenuItem(value: 'priority', child: Text("Sort by Priority")),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.group_add_rounded, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectMembersScreen(projectId: projectId))),
        ),
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
          onPressed: () => _showDeleteConfirmation(context, ref),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPremiumDescription(BuildContext context, WidgetRef ref, Project project, bool isDark) {
    return GestureDetector(
      onTap: () => _showEditDescriptionDialog(context, ref, project),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("PROJECT DESCRIPTION", style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2)),
                const Spacer(),
                Icon(Icons.edit_rounded, color: AppColors.primary.withOpacity(0.5), size: 18),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              project.description ?? "Tap to add a description for this project.",
              style: TextStyle(
                fontSize: 15, 
                height: 1.6, 
                color: project.description == null ? Colors.black26 : (isDark ? Colors.white70 : const Color(0xFF1F2937)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernProgressHeader(WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return StreamBuilder<List<Task>>(
      stream: (db.select(db.tasks)..where((t) => t.projectId.equals(projectId))).watch(),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) return const SizedBox.shrink();

        final done = tasks.where((t) => t.status == TaskStatus.done.name).length;
        final progress = done / tasks.length;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Completion Progress", style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF4B5563), fontSize: 13)),
                  Text("${(progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFFF3F4F6),
                  color: AppColors.primary,
                  minHeight: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/tasks/new?projectId=$projectId'),
      elevation: 4,
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add_task_rounded, color: Colors.white),
      label: const Text("Add Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  // --- LOGIC FUNCTIONS ---

  Future<void> _toggleTaskStatus(WidgetRef ref, Task task) async {
    final db = ref.read(databaseProvider);
    final isDone = task.status == TaskStatus.done.name;
    final newStatus = isDone ? TaskStatus.todo.name : TaskStatus.done.name;

    await (db.update(db.tasks)..where((t) => t.id.equals(task.id))).write(
      TasksCompanion(status: drift.Value(newStatus)),
    );
  }

  void _showEditDescriptionDialog(BuildContext context, WidgetRef ref, Project project) {
    final controller = TextEditingController(text: project.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Edit Description", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          style: const TextStyle(color: Color(0xFF1A1C1E)),
          decoration: InputDecoration(
            hintText: "What is this project about?",
            filled: true,
            fillColor: const Color(0xFFF8F9FD),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await (db.update(db.projects)..where((p) => p.id.equals(project.id))).write(
                ProjectsCompanion(description: drift.Value(controller.text.trim())),
              );
              ref.invalidate(allProjectsProvider);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Delete Project?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("This action cannot be undone. All tasks in this project will also be deleted."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseProvider);
      await (db.delete(db.tasks)..where((t) => t.projectId.equals(projectId))).go();
      await (db.delete(db.projects)..where((p) => p.id.equals(projectId))).go();
      ref.invalidate(allProjectsProvider);
      if (context.mounted) context.pop();
    }
  }
}