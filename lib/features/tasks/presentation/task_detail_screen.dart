import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/task_providers.dart';
import '../../../data/database/database.dart';
import '../../../data/models/enums.dart';

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
        title: const Text(
          'Task Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= TITLE =================
            Text(
              task.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            /// ================= STATUS =================
            _infoChip(
              label: task.status?.toUpperCase() ?? 'TODO',
              color: _statusColor(task.status),
            ),

            const SizedBox(height: 24),

            /// ================= DESCRIPTION =================
            _sectionTitle('Description'),
            const SizedBox(height: 8),
            Text(
              task.description?.isNotEmpty == true
                  ? task.description!
                  : 'No description added',
              style: TextStyle(
                fontSize: 14,
                color:
                isDark ? Colors.white70 : Colors.black54,
              ),
            ),

            const SizedBox(height: 24),

            /// ================= DETAILS =================
            _sectionTitle('Details'),
            const SizedBox(height: 12),

            _detailRow('Priority', _priorityText(task.priority)),
            _detailRow(
              'Due Date',
              task.dueDate != null
                  ? _formatDate(task.dueDate!)
                  : 'Not set',
            ),
            _detailRow(
              'Project',
              task.projectId != null
                  ? 'Project #${task.projectId}'
                  : 'No project',
            ),
            _detailRow(
              'Assignee',
              task.assigneeId != null
                  ? 'User ${task.assigneeId}'
                  : 'Unassigned',
            ),

            const SizedBox(height: 32),

            /// ================= MARK DONE =================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(
                  task.status == TaskStatus.done.name
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                ),
                label: Text(
                  task.status == TaskStatus.done.name
                      ? 'Completed'
                      : 'Mark as Done',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  task.status == TaskStatus.done.name
                      ? Colors.green
                      : AppColors.primary,
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  final newStatus =
                  task.status == TaskStatus.done.name
                      ? TaskStatus.todo.name
                      : TaskStatus.done.name;

                  ref.read(tasksProvider.notifier).updateTask(
                    task.copyWith(
                      status: drift.Value(newStatus),
                    ),
                  );

                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required String label,
    required Color color,
  }) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color,
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  String _priorityText(int? p) {
    switch (p) {
      case 3:
        return 'High';
      case 2:
        return 'Medium';
      case 1:
      default:
        return 'Low';
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}