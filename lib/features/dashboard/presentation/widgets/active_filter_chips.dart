import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/enums.dart';

class ActiveFilterChips extends StatelessWidget {
  final Set<TaskStatus> statuses;
  final Set<Priority> priorities;
  final String? due;
  final VoidCallback onClearAll;

  const ActiveFilterChips({
    super.key,
    required this.statuses,
    required this.priorities,
    required this.due,
    required this.onClearAll,
  });

  bool get hasFilters =>
      statuses.isNotEmpty || priorities.isNotEmpty || due != null;

  @override
  Widget build(BuildContext context) {
    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...statuses.map(
                (s) => _chip(
              label: _statusLabel(s),
              color: AppColors.primary,
            ),
          ),
          ...priorities.map(
                (p) => _chip(
              label: _priorityLabel(p),
              color: Colors.orange,
            ),
          ),
          if (due != null)
            _chip(
              label: due!,
              color: Colors.green,
            ),
          ActionChip(
            label: const Text('Clear'),
            onPressed: onClearAll,
            backgroundColor: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  Widget _chip({required String label, required Color color}) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
    );
  }

  /// ❌ DO NOT USE TaskStatus.label (causes error)
  String _statusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.review:
        return 'Review';
      case TaskStatus.done:
        return 'Done';
    }
  }

  String _priorityLabel(Priority p) {
    switch (p) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';

    }
  }
}