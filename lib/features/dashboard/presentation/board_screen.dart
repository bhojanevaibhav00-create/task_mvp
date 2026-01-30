import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 🚀 Essential: Use database model instead of task_model.dart to avoid conflicts
import '../../../../data/database/database.dart' as db;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/task_providers.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/board_column.dart';

class BoardScreen extends ConsumerWidget {
  final db.Project project;

  const BoardScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 Watching the live filtered tasks from provider
    final tasksAsync = ref.watch(filteredTasksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: tasksAsync.when(
        data: (allTasks) {
          // Filter tasks belonging to this project and specific status
          // Note: Backend uses 'todo', 'inProgress', 'done' as Strings
          final List<db.Task> projectTasks = allTasks.where((t) => t.projectId == project.id).toList();

          final todoTasks = projectTasks.where((t) => t.status == 'todo').toList();
          final inProgressTasks = projectTasks.where((t) => t.status == 'inProgress').toList();
          final doneTasks = projectTasks.where((t) => t.status == 'done').toList();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildColumnWrapper("To Do", todoTasks, AppColors.primary),
                const SizedBox(width: 16),
                _buildColumnWrapper("In Progress", inProgressTasks, Colors.orange),
                const SizedBox(width: 16),
                _buildColumnWrapper("Done", doneTasks, Colors.green),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildColumnWrapper(String title, List<db.Task> tasks, Color accentColor) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFEBEDF0).withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text("${tasks.length}", 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ),
          Flexible(
            child: BoardColumn(
              title: title, 
              tasks: tasks, // 🚀 Error gone: Both use db.Task now
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}