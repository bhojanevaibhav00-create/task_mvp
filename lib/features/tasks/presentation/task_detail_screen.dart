import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/database/database.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/assignee_chip.dart';

class TaskDetailScreen extends ConsumerWidget {
  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== TITLE =====
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            /// ===== DESCRIPTION =====
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),

            const SizedBox(height: 24),

            /// ===== ASSIGNEE =====
            const Text(
              'Assigned To',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            AssigneeChip(
              /// ✅ FIXED — NEVER NULL
              name: task.assigneeId != null
                  ? 'User ${task.assigneeId}'
                  : 'Unassigned',
              showClear: false,
              onTap: () {
                // later: open AssignMemberSheet
              },
            ),

            const SizedBox(height: 24),

            /// ===== META =====
            _infoRow('Status', task.status ?? '-'),
            _infoRow('Priority', task.priority.toString()),
            _infoRow(
              'Project',
              task.projectId != null ? task.projectId.toString() : '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}