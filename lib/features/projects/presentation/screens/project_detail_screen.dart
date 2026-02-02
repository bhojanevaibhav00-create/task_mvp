import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

import 'package:task_mvp/core/constants/app_colors.dart';
import 'package:task_mvp/core/providers/task_providers.dart';
import 'package:task_mvp/core/providers/collaboration_providers.dart'; 
import 'package:task_mvp/features/projects/widgets/add_member_dialog.dart'; 
import 'package:task_mvp/features/tasks/presentation/widgets/task_card.dart'; 
import 'package:task_mvp/data/database/database.dart';
import 'package:task_mvp/data/models/enums.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final int projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(allProjectsProvider);
    final db = ref.watch(databaseProvider);

    return projectsAsync.when(
      data: (projects) {
        final project = projects.firstWhere((p) => p.id == projectId);
        
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w900)),
            actions: [
              // ✅ NEW: Delete Project Option
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                tooltip: "Delete Project",
                onPressed: () => _showDeleteConfirmation(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.group_add_rounded, color: Colors.white),
                tooltip: "Manage Team",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProjectMembersScreen(projectId: projectId),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildInfoCard(project.description ?? "No description provided"),
                    const SizedBox(height: 24),
                    
                    // ✅ NEW: Progress Header
                    _buildProgressHeader(db),
                    
                    const SizedBox(height: 32),
                    const Text(
                      "Project Tasks",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E)),
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
              
              StreamBuilder<List<Task>>(
                stream: (db.select(db.tasks)..where((t) => t.projectId.equals(projectId))).watch(),
                builder: (context, snapshot) {
                  final tasks = snapshot.data ?? [];

                  if (tasks.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text("No tasks in this project yet", style: TextStyle(color: Colors.black38))),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = tasks[index];
                          return TaskCard(
                            task: task,
                            onTap: () => context.push('/tasks/${task.id}'),
                            // ✅ FIXED: Real toggle logic
                            onToggleDone: () => _toggleTaskStatus(ref, task),
                          );
                        },
                        childCount: tasks.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            onPressed: () => context.push('/tasks/new?projectId=$projectId'),
            label: const Text("Add Project Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Error: $e"))),
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

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Project?"),
        content: const Text("This will permanently remove the project and all its tasks."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseProvider);
      // Delete tasks first (or rely on Cascade if set up in drift)
      await (db.delete(db.tasks)..where((t) => t.projectId.equals(projectId))).go();
      await (db.delete(db.projects)..where((p) => p.id.equals(projectId))).go();
      
      ref.invalidate(allProjectsProvider);
      if (context.mounted) context.pop();
    }
  }

  // --- UI WIDGETS ---

  Widget _buildProgressHeader(AppDatabase db) {
    return StreamBuilder<List<Task>>(
      stream: (db.select(db.tasks)..where((t) => t.projectId.equals(projectId))).watch(),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) return const SizedBox.shrink();

        final done = tasks.where((t) => t.status == TaskStatus.done.name).length;
        final progress = done / tasks.length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.03)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Progress", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  Text("${(progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFF0F4FF),
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                minHeight: 8,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String desc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Description", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87)),
        ],
      ),
    );
  }
}