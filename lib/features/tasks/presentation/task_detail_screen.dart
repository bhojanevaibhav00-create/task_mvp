import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:task_mvp/features/tasks/presentation/widgets/comment_input.dart';
import 'package:task_mvp/features/tasks/presentation/widgets/comment_tile.dart';

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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const backgroundColor = Color(0xFFF8F9FD);
    const darkSlate = Color(0xFF1A1C1E);
    
    // Watch Real-time Data
    final subtasksAsync = ref.watch(subtasksStreamProvider(widget.task.id));
    final commentsAsync = ref.watch(taskCommentsProvider(widget.task.id));

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.scaffoldDark : Colors.white,
        foregroundColor: isDark ? Colors.white : darkSlate,
        title: const Text('Task Management', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
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
          /// --- HEADER ---
          Text(
            widget.task.title,
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w900, 
              color: isDark ? Colors.white : darkSlate, 
              letterSpacing: -0.5
            ),
          ),
          const SizedBox(height: 12),
          
          if (widget.task.description != null && widget.task.description!.isNotEmpty) ...[
            Text(
              widget.task.description!,
              style: TextStyle(
                fontSize: 16, 
                color: isDark ? Colors.white70 : Colors.black54, 
                height: 1.5
              ),
            ),
            const SizedBox(height: 32),
          ],

          _buildSectionHeader('ASSIGNMENT'),
          AssigneeChip(
            name: assignedName ?? (widget.task.assigneeId != null ? 'User ${widget.task.assigneeId}' : 'Unassigned'),
            showClear: widget.task.assigneeId != null,
            onTap: () => _handleAssignMember(context),
          ),
          const SizedBox(height: 24),

          _buildInfoRow('Status', widget.task.status ?? 'To Do', isDark),
          _buildInfoRow('Priority', _getPriorityLabel(widget.task.priority), isDark),
          _buildInfoRow('Due Date', widget.task.dueDate?.toString().split(' ')[0] ?? 'No Date', isDark),

          const Divider(height: 64),

          /// ✅ SECTION 1: SUBTASKS
          _buildSectionHeader('SUBTASKS'),
          subtasksAsync.when(
            data: (subtasks) => _buildSubtaskColumn(subtasks),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error loading subtasks: $e'),
          ),
          const SizedBox(height: 16),
          _buildAddSubtaskField(),

          const Divider(height: 64),

          /// ✅ SECTION 2: ACTIVITY TIMELINE
          _buildSectionHeader('ACTIVITY TIMELINE'),
          _buildTimeline(isDark),

          const Divider(height: 64),

          /// ✅ SECTION 3: COMMENTS
          _buildSectionHeader('COMMENTS'),
          commentsAsync.when(
            data: (comments) {
              if (comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("No comments yet. Mention someone with @", 
                    style: TextStyle(color: Colors.black26, fontSize: 13)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) => CommentTile(commentData: comments[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 20),
          CommentInput(
            taskId: widget.task.id,
            projectId: widget.task.projectId ?? 0,
          ),
          
          const SizedBox(height: 80), 
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSubtaskColumn(List<Subtask> subtasks) {
    if (subtasks.isEmpty) return const Text("No subtasks yet.", style: TextStyle(color: Colors.black26));
    
    return Column(
      children: subtasks.map((st) => CheckboxListTile(
        value: st.isCompleted,
        title: Text(st.title, style: TextStyle(decoration: st.isCompleted ? TextDecoration.lineThrough : null)),
        contentPadding: EdgeInsets.zero,
        onChanged: (val) {
          ref.read(subtaskRepositoryProvider).toggleSubtask(st.id, val ?? false);
          ref.invalidate(projectProgressProvider);
        },
      )).toList(),
    );
  }

  Widget _buildAddSubtaskField() {
    return TextButton.icon(
      onPressed: () => _showAddSubtaskDialog(),
      icon: const Icon(Icons.add_circle_outline, size: 20),
      label: const Text("Add Subtask"),
    );
  }

  Widget _buildTimeline(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _timelineItem("Task Created", "System", "Just now"),
        _timelineItem("Priority set to High", "Vaibhav", "2 hours ago"),
      ],
    );
  }

  Widget _timelineItem(String action, String user, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text("$action by $user", style: const TextStyle(fontSize: 13))),
          Text(time, style: const TextStyle(fontSize: 12, color: Colors.black26)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 1.2)),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black26, letterSpacing: 1.1))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1A1C1E))),
        ],
      ),
    );
  }

  // --- LOGIC HELPERS ---

  String _getPriorityLabel(int? priority) => switch (priority) { 3 => 'High', 2 => 'Medium', _ => 'Low' };

  void _handleAssignMember(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssignMemberSheet(projectId: widget.task.projectId ?? 0),
    );
    if (result != null) setState(() => assignedName = result.user.name);
  }

  void _showAddSubtaskDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New Subtask"),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: "What needs to be done?")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(onPressed: () {
            if (controller.text.isNotEmpty) {
              ref.read(subtaskRepositoryProvider).addSubtask(
                SubtasksCompanion.insert(title: controller.text, taskId: widget.task.id));
              ref.invalidate(projectProgressProvider);
              Navigator.pop(ctx);
            }
          }, child: const Text("Add")),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Delete Task?", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
        content: const Text("This task will be removed from your workspace."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
      await (dbRepo.delete(dbRepo.tasks)..where((t) => t.id.equals(widget.task.id))).go();
      if (mounted) {
        Navigator.pop(context);
        context.pop();
      }
      ref.invalidate(tasksProvider);
      ref.invalidate(projectProgressProvider);
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }
}