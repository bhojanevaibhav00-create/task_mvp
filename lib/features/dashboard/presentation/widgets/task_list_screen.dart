import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:task_mvp/core/constants/app_colors.dart';
import 'package:task_mvp/core/providers/task_providers.dart';
import 'package:task_mvp/data/database/database.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/task_tile.dart';
import 'package:task_mvp/features/tasks/presentation/task_detail_screen.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: tasks.isEmpty
          ? const Center(child: Text('No tasks found'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final Task task = tasks[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TaskTile(
              task: task,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TaskDetailScreen(task: task),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}