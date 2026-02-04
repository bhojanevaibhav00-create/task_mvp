import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/enums.dart';

class ActiveFilterChips extends StatelessWidget {
  final Set<TaskStatus> statuses;
  final Set<Priority> priorities;
  final String? due;
  final VoidCallback onClear;

  const ActiveFilterChips({
    super.key,
    required this.statuses,
    required this.priorities,
    required this.due,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    for (final s in statuses) {
      chips.add(_chip('Status: ${s.name}'));
    }

    for (final p in priorities) {
      chips.add(_chip('Priority: ${p.label}'));
    }

    if (due != null) {
      chips.add(_chip('Due: $due'));
    }

    if (chips.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...chips,
          ActionChip(
            label: const Text('Clear all'),
            onPressed: onClear,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.grey.shade200,
    );
  }
}

