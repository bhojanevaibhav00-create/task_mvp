import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
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
  ConsumerState<TaskDetailScreen> createState() =>
      _TaskDetailScreenState();
}

class _TaskDetailScreenState
    extends ConsumerState<TaskDetailScreen> {
  String? assignedName;

  @override
  void initState() {
    super.initState();
    assignedName = null; // UI-only for now
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : Colors.white,
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.task.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),

          /// ===== ASSIGNED TO =====
          const Text(
            'Assigned To',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          AssigneeChip(
            name: assignedName,
            showClear: true,
            onTap: () async {
              final result = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => AssignMemberSheet(
                  projectId: widget.task.projectId ?? 0,
                ),
              );

              setState(() {
                assignedName = result?.user.name;
              });
            },
          ),
        ],
      ),
    );
  }
}