import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/task_providers.dart' hide notificationRepositoryProvider;
import 'package:task_mvp/core/providers/notification_providers.dart';
import 'package:task_mvp/core/providers/database_provider.dart';
import '../../../../data/database/database.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/assignee_chip.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/assign_member_sheet.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  String? assignedName;

  @override
  void initState() {
    super.initState();
    // Initialize with existing assignee if available
    assignedName = null; 
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const backgroundColor = Color(0xFFF8F9FD); 
    const darkSlate = Color(0xFF1A1C1E);

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.scaffoldDark : Colors.white,
        foregroundColor: isDark ? Colors.white : darkSlate,
        title: const Text(
          'Task Details',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () => _showDeleteDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.task.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : darkSlate,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          
          if (widget.task.description != null && widget.task.description!.isNotEmpty) ...[
            Text(
              widget.task.description!,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
          ],

          const Text(
            'ASSIGNEE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.black26,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          AssigneeChip(
            name: assignedName ?? (widget.task.assigneeId != null ? 'User ${widget.task.assigneeId}' : 'Unassigned'),
            showClear: widget.task.assigneeId != null,
            onTap: () async {
              final result = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AssignMemberSheet(
                  projectId: widget.task.projectId ?? 0,
                ),
              );

              if (result != null) {
                setState(() {
                  assignedName = result.user.name;
                });
              }
            },
          ),
          
          const SizedBox(height: 32),

          /// ===== TASK META INFO =====
          _buildInfoRow('Status', widget.task.status ?? 'To Do', isDark),
          _buildInfoRow('Priority', _getPriorityLabel(widget.task.priority), isDark),
          _buildInfoRow('Due Date', widget.task.dueDate?.toString().split(' ')[0] ?? 'No Date', isDark),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black26, letterSpacing: 1.1),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1A1C1E)),
          ),
        ],
      ),
    );
  }

  String _getPriorityLabel(int? priority) {
    return switch (priority) {
      3 => 'High',
      2 => 'Medium',
      _ => 'Low',
    };
  }

  // ================= DELETE LOGIC (FIXED HANG & NOTIFICATION) =================

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Delete Task?", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
        content: const Text("This task will be removed from your workspace."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _handleDelete(context),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    try {
      final dbRepo = ref.read(databaseProvider);
      
      // 1. Database Delete
      await (dbRepo.delete(dbRepo.tasks)..where((t) => t.id.equals(widget.task.id))).go();

      // 2. ✅ FIXED: Aligning with NotificationRepository signature
      await ref.read(notificationRepositoryProvider).addNotification(
        title: "Task Deleted",
        message: "The task '${widget.task.title}' was successfully removed.",
        type: "system", // Required parameter
        taskId: widget.task.id,
        projectId: widget.task.projectId,
      );

      // 3. 🚀 NAVIGATION FIX: Pop context before invalidating providers to prevent state rebuild "hang"
      if (mounted) {
        Navigator.pop(context); // Close Dialog
        context.pop();          // Return to Task List/Dashboard
      }

      // 4. State Refresh (Happens after we are safely off this screen)
      ref.invalidate(tasksProvider);
      ref.invalidate(filteredTasksProvider);

    } catch (e) {
      debugPrint("Delete Error: $e");
      if (mounted) Navigator.pop(context);
    }
  }
}