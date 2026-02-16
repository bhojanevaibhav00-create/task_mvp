import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/database/database.dart';
import '../../../../core/providers/task_providers.dart'; 
import '../../../../core/providers/database_provider.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/assignee_chip.dart';
import 'task_create_edit_screen.dart'; // ✅ Added for navigation

// ✅ Fixed imports to ensure widgets are visible to the compiler
import 'package:task_mvp/features/tasks/presentation/widgets/comment_tile.dart';
import 'package:task_mvp/features/tasks/presentation/widgets/comment_input.dart';

class TaskDetailScreen extends ConsumerWidget {
  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111827);
    final db = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent, // ✅ More modern look
        iconTheme: IconThemeData(color: primaryTextColor),
        centerTitle: true,
        title: Text(
          'Task Details',
          style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // ✅ NEW: Premium Edit Button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TaskCreateEditScreen(task: task)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== TITLE SECTION =====
            Text(
              task.title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            /// ===== DESCRIPTION CARD =====
            if (task.description != null && task.description!.isNotEmpty)
              _buildModernCard(
                isDark,
                child: Text(
                  task.description!,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            /// ===== 1B: PROGRESS BAR SECTION =====
            ref.watch(subtasksProvider(task.id)).when(
              data: (subtasks) {
                if (subtasks.isEmpty) return const SizedBox.shrink();
                final completed = subtasks.where((s) => s.isCompleted).length;
                final progress = completed / subtasks.length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('PROGRESS', isDark),
                    const SizedBox(height: 12),
                    _buildModernCard(
                      isDark,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(progress * 100).toInt()}% Completed',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              Text('$completed / ${subtasks.length} subtasks', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            /// ===== ASSIGNEE =====
            _sectionHeader('ASSIGNED TO', isDark),
            const SizedBox(height: 12),
            AssigneeChip(
              name: task.assigneeId != null ? 'User ${task.assigneeId}' : 'Unassigned',
              showClear: false,
              onTap: () {},
            ),

            const SizedBox(height: 32),

            /// ===== META INFORMATION CARD =====
            _sectionHeader('INFORMATION', isDark),
            const SizedBox(height: 12),
            _buildModernCard(
              isDark,
              child: Column(
                children: [
                  _infoRow(Icons.radio_button_checked_rounded, 'Status', task.status?.toUpperCase() ?? 'TODO', isDark),
                  const Divider(height: 24),
                  _infoRow(Icons.bolt_rounded, 'Priority', _getPriorityLabel(task.priority), isDark),
                  const Divider(height: 24),
                  _infoRow(Icons.folder_rounded, 'Project', task.projectId != null ? 'Project #${task.projectId}' : 'General', isDark),
                ],
              ),
            ),

            const SizedBox(height: 32),

            /// ===== 1B: SUBTASKS LIST =====
            _sectionHeader('SUBTASKS', isDark),
            const SizedBox(height: 12),
            ref.watch(subtasksProvider(task.id)).when(
              data: (list) {
                if (list.isEmpty) return const Text("No subtasks added.");
                return _buildModernCard(
                  isDark,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: list.map((sub) => CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(sub.title, style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 14,
                        decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                      )),
                      value: sub.isCompleted,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        db.update(db.subtasks).replace(sub.copyWith(isCompleted: val ?? false));
                      },
                    )).toList(),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 32),

            /// ===== 1C: COMMENTS SECTION =====
            _sectionHeader('COMMENTS', isDark),
            const SizedBox(height: 16),
            ref.watch(commentsProvider(task.id)).when(
              data: (comments) {
                if (comments.isEmpty) return const Text("No comments yet.");
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) => CommentTile(comment: comments[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            
            const SizedBox(height: 16),
            CommentInput(
              taskId: task.id, 
              projectId: task.projectId ?? 0,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 🎨 Helper for Modern Card Design
  Widget _buildModernCard(bool isDark, {required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  String _getPriorityLabel(dynamic priority) {
    if (priority == null) return "Low";
    final pValue = int.tryParse(priority.toString()) ?? 1;
    if (pValue >= 3) return "🔥 High";
    if (pValue == 2) return "⚡ Medium";
    return "🍃 Low";
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: isDark ? Colors.white38 : Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary.withOpacity(0.7)),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}