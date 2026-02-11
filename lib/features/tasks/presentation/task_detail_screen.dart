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
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.scaffoldDark : Colors.white,
        iconTheme: IconThemeData(color: primaryTextColor),
        title: Text(
          'Task Details',
          style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== TITLE =====
            Text(
              task.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: primaryTextColor,
              ),
            ),

            const SizedBox(height: 16),

            /// ===== DESCRIPTION =====
            if (task.description != null && task.description!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  task.description!,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            /// ===== ASSIGNEE =====
            _sectionHeader('ASSIGNED TO', isDark),
            const SizedBox(height: 12),
            AssigneeChip(
              name: task.assigneeId != null
                  ? 'User ${task.assigneeId}'
                  : 'Unassigned',
              showClear: false,
              onTap: () {},
            ),

            const SizedBox(height: 32),

            /// ===== META INFORMATION =====
            _sectionHeader('INFORMATION', isDark),
            const SizedBox(height: 16),

            _infoRow('Status', task.status ?? 'Pending', isDark),
            
            /// ✅ THE FIX: Force conversion to String and handle potential nulls
            _infoRow('Priority', _getPriorityLabel(task.priority), isDark),
            
            _infoRow(
              'Project',
              task.projectId != null ? 'Project #${task.projectId}' : 'General',
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Logic to handle 'int' or 'int?' safely
  String _getPriorityLabel(dynamic priority) {
    if (priority == null) return "Low";
    
    // Convert to int if it's currently a different type
    final pValue = int.tryParse(priority.toString()) ?? 1;
    
    if (pValue >= 3) return "🔥 High";
    if (pValue == 2) return "⚡ Medium";
    return "🍃 Low";
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: isDark ? Colors.white38 : Colors.grey.shade500,
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}