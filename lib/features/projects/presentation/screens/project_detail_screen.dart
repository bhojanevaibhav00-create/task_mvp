import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

// Core Constants & Providers
import 'package:task_mvp/core/constants/app_colors.dart';
import 'package:task_mvp/core/providers/task_providers.dart';
import 'package:task_mvp/core/providers/project_providers.dart';
import 'package:task_mvp/core/providers/database_provider.dart';
import 'package:task_mvp/features/tasks/presentation/widgets/task_card.dart';
import 'package:task_mvp/data/database/database.dart';
import 'package:task_mvp/data/models/enums.dart';
import 'package:task_mvp/features/tasks/presentation/task_create_edit_screen.dart';
import '../project_members_screen.dart';

/// ✅ LOCAL PROVIDER: Manages task sorting state for this specific screen
final projectSortProvider = StateProvider.autoDispose<String>((ref) => 'date');

class ProjectDetailScreen extends ConsumerWidget {
  final int projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. WATCH: Listen to the stream of projects for real-time updates
    final projectsAsync = ref.watch(allProjectsProvider);
    final db = ref.watch(databaseProvider);
    final currentSort = ref.watch(projectSortProvider);

    // 2. THEME: Detect brightness for adaptive UI
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return projectsAsync.when(
      data: (projects) {
        // Find the specific project in the list
        final project = projects.where((p) => p.id == projectId).firstOrNull;

        // Fallback if project was deleted or not found
        if (project == null) {
          return Scaffold(
            backgroundColor: isDark
                ? AppColors.scaffoldDark
                : const Color(0xFFF8F9FD),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Project not found",
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.scaffoldDark
              : const Color(0xFFF8F9FD),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- 1. PREMIUM SLIVER APP BAR ---
              _buildModernAppBar(context, ref, project, isDark),

              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // --- 2. EDITABLE DESCRIPTION CARD ---
                    _buildPremiumDescription(context, ref, project, isDark),
                    const SizedBox(height: 24),

                    // --- 3. PROJECT PROGRESS (REAL-TIME) ---
                    _buildModernProgressHeader(db, isDark),
                    const SizedBox(height: 32),

                    // --- 4. SECTION HEADER & SORT INFO ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.list_alt_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Project Tasks",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1C1E),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Sorted by ${currentSort == 'priority' ? 'Priority' : 'Date'}",
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),

              // --- 5. DYNAMIC TASK LIST (DRIFT STREAM) ---
              StreamBuilder<List<Task>>(
                stream:
                    (db.select(db.tasks)
                          ..where((t) => t.projectId.equals(projectId))
                          ..orderBy([
                            (t) => drift.OrderingTerm(
                              expression: currentSort == 'priority'
                                  ? t.priority
                                  : t.dueDate,
                              mode: drift.OrderingMode.asc,
                            ),
                          ]))
                        .watch(),
                builder: (context, snapshot) {
                  final tasks = snapshot.data ?? [];

                  if (tasks.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_late_outlined,
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade300,
                              size: 60,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No tasks found in this project",
                              style: TextStyle(
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: TaskCard(
                            task: tasks[index],
                            onTap: () =>
                                _openEditTask(context, ref, tasks[index]),
                            onToggleDone: () {
                              final task = tasks[index];
                              final isDone =
                                  task.status == TaskStatus.done.name;
                              final newStatus = isDone
                                  ? TaskStatus.todo.name
                                  : TaskStatus.done.name;
                              ref
                                  .read(tasksProvider.notifier)
                                  .updateTask(
                                    task.copyWith(
                                      status: drift.Value(newStatus),
                                    ),
                                  );
                            },
                          ),
                        );
                      }, childCount: tasks.length),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/tasks/new?projectId=$projectId'),
            elevation: 4,
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add_task_rounded, color: Colors.white),
            label: const Text(
              "Add Task",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text("Error loading project: $e"))),
    );
  }

  // ================= UI HELPERS =================

  Widget _buildModernAppBar(
    BuildContext context,
    WidgetRef ref,
    Project project,
    bool isDark,
  ) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 18),
        title: Text(
          project.name,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 20,
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
              right: -20,
              top: -20,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white.withOpacity(0.05),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Sort Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort_rounded, color: Colors.white),
          onSelected: (value) =>
              ref.read(projectSortProvider.notifier).state = value,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'date', child: Text("Sort by Date")),
            const PopupMenuItem(
              value: 'priority',
              child: Text("Sort by Priority"),
            ),
          ],
        ),
        // Members Action
        IconButton(
          icon: const Icon(Icons.group_add_outlined, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectMembersScreen(projectId: projectId),
            ),
          ),
        ),
        // Delete Action
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          onPressed: () =>
              _showDeleteConfirmation(context, ref, project.name, isDark),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPremiumDescription(
    BuildContext context,
    WidgetRef ref,
    Project project,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _showEditDescriptionDialog(context, ref, project, isDark),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: isDark
              ? Border.all(color: Colors.white.withOpacity(0.05))
              : null,
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "PROJECT DESCRIPTION",
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.edit_rounded,
                  color: AppColors.primary.withOpacity(0.4),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              project.description ??
                  "Tap to add a detailed project overview...",
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: project.description == null
                    ? (isDark ? Colors.white12 : Colors.black26)
                    : (isDark ? Colors.white70 : const Color(0xFF1F2937)),
                fontStyle: project.description == null
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernProgressHeader(AppDatabase db, bool isDark) {
    return StreamBuilder<List<Task>>(
      stream: (db.select(
        db.tasks,
      )..where((t) => t.projectId.equals(projectId))).watch(),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) return const SizedBox.shrink();

        final done = tasks
            .where((t) => t.status == TaskStatus.done.name)
            .length;
        final double progress = tasks.isEmpty ? 0.0 : done / tasks.length;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: isDark
                ? Border.all(color: Colors.white.withOpacity(0.05))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Completion Progress",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "${(progress * 100).toInt()}%",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Stack(
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 10,
                    width: (MediaQuery.of(context).size.width - 88) * progress,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "$done of ${tasks.length} tasks completed",
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= LOGIC & DIALOGS =================

  void _openEditTask(BuildContext context, WidgetRef ref, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskCreateEditScreen(task: task)),
    ).then((changed) {
      if (changed == true) ref.read(tasksProvider.notifier).loadTasks();
    });
  }

  void _showEditDescriptionDialog(
    BuildContext context,
    WidgetRef ref,
    Project project,
    bool isDark,
  ) {
    final controller = TextEditingController(text: project.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Edit Description",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: "Enter project goals or details...",
            hintStyle: TextStyle(
              color: isDark ? Colors.white10 : Colors.black12,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF8F9FD),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await (db.update(
                db.projects,
              )..where((p) => p.id.equals(project.id))).write(
                ProjectsCompanion(
                  description: drift.Value(controller.text.trim()),
                ),
              );
              // Invalidate to refresh UI
              ref.invalidate(allProjectsProvider);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    String projectName,
    bool isDark,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Delete $projectName?",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This will permanently remove the project and all associated tasks.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // ✅ SUCCESS: Calls the controller which handles DB + Notification logic
      await ref
          .read(projectControllerProvider)
          .deleteProject(projectId, projectName);

      if (context.mounted) context.pop();
    }
  }
}
