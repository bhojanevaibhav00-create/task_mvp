import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/task_providers.dart';
import '../../../../data/database/database.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/assignee_chip.dart';
import '../../../tasks/presentation/task_detail_screen.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final int projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTasks = ref.watch(tasksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    /// ✅ FILTER PROJECT TASKS (SAFE)
    final projectTasks =
    allTasks.where((t) => t.projectId == projectId).toList();

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      appBar: AppBar(
        title: const Text('Project Details'),
      ),
      body: projectTasks.isEmpty
          ? const Center(child: Text('No tasks in this project'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: projectTasks.length,
        itemBuilder: (context, index) {
          final Task task = projectTasks[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
              isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TaskDetailScreen(task: task),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 TITLE
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// 🔹 ASSIGNEE BADGE
                  AssigneeChip(
                    name: task.assigneeId != null
                        ? 'Assigned'
                        : null,
                    showClear: false,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}