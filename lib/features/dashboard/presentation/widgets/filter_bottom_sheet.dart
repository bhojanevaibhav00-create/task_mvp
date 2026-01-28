import 'package:flutter/material.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/tag_model.dart';
import '../../../../core/constants/app_colors.dart';

void openFilterBottomSheet({
  required BuildContext context,
  required List<Tag> allTags,
  required Set<TaskStatus> statusFilters,
  required Set<Priority> priorityFilters,
  required Set<Tag> tagFilters,
  required String? dueBucket,
  required String? sort,
  required Function(
      Set<TaskStatus>,
      Set<Priority>,
      Set<Tag>,
      String?,
      String?,
      ) onApply,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FilterSheet(
      allTags: allTags,
      status: statusFilters,
      priority: priorityFilters,
      tags: tagFilters,
      dueBucket: dueBucket,
      sort: sort,
      onApply: onApply,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  final List<Tag> allTags;
  final Set<TaskStatus> status;
  final Set<Priority> priority;
  final Set<Tag> tags;
  final String? dueBucket;
  final String? sort;
  final Function(
      Set<TaskStatus>,
      Set<Priority>,
      Set<Tag>,
      String?,
      String?,
      ) onApply;

  const _FilterSheet({
    required this.allTags,
    required this.status,
    required this.priority,
    required this.tags,
    required this.dueBucket,
    required this.sort,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<TaskStatus> status;
  late Set<Priority> priority;
  late Set<Tag> tags;
  String? dueBucket;

  @override
  void initState() {
    super.initState();
    status = {...widget.status};
    priority = {...widget.priority};
    tags = {...widget.tags};
    dueBucket = widget.dueBucket;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dragHandle(),
          const SizedBox(height: 16),

          Text(
            'Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 20),

          _section(
            'Status',
            TaskStatus.values.map(_statusChip).toList(),
          ),
          _section(
            'Priority',
            Priority.values.map(_priorityChip).toList(),
          ),
          _section(
            'Due',
            ['Today', 'Overdue', 'Next 7 Days'].map(_dueChip).toList(),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                      status,
                      priority,
                      tags,
                      dueBucket,
                      widget.sort,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> chips) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }

  // ================= CHIPS =================

  Widget _statusChip(TaskStatus s) {
    final selected = status.contains(s);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(
        s.name,
        style: TextStyle(
          color: selected
              ? Colors.white
              : isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor:
      isDark ? AppColors.cardDark : AppColors.chipBackground,
      onSelected: (_) =>
          setState(() => selected ? status.remove(s) : status.add(s)),
    );
  }

  Widget _priorityChip(Priority p) {
    final selected = priority.contains(p);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(
        p.name,
        style: TextStyle(
          color: selected
              ? Colors.white
              : isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor:
      isDark ? AppColors.cardDark : AppColors.chipBackground,
      onSelected: (_) =>
          setState(() => selected ? priority.remove(p) : priority.add(p)),
    );
  }

  Widget _dueChip(String d) {
    final selected = dueBucket == d;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(
        d,
        style: TextStyle(
          color: selected
              ? Colors.white
              : isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor:
      isDark ? AppColors.cardDark : AppColors.chipBackground,
      onSelected: (_) =>
          setState(() => dueBucket = selected ? null : d),
    );
  }
}
