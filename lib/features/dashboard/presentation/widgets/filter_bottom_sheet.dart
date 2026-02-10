import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/tag_model.dart';

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
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HANDLE =================
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ================= TITLE =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    status.clear();
                    priority.clear();
                    tags.clear();
                    dueBucket = null;
                  });
                },
                child: const Text('Clear'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _sectionTitle('Status'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskStatus.values.map(_statusChip).toList(),
          ),

          const SizedBox(height: 20),

          _sectionTitle('Priority'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Priority.values.map(_priorityChip).toList(),
          ),

          const SizedBox(height: 20),

          _sectionTitle('Due'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Today', 'Overdue', 'Next 7 Days']
                .map(_dueChip)
                .toList(),
          ),

          const SizedBox(height: 28),

          // ================= APPLY BUTTON =================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
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
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // =========================================================
  // CHIPS
  // =========================================================

  Widget _statusChip(TaskStatus s) {
    final selected = status.contains(s);
    return ChoiceChip(
      label: Text(s.name),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.primarySoft,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) =>
          setState(() => selected ? status.remove(s) : status.add(s)),
    );
  }

  Widget _priorityChip(Priority p) {
    final selected = priority.contains(p);
    return ChoiceChip(
      label: Text(p.name),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.primarySoft,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) =>
          setState(() => selected ? priority.remove(p) : priority.add(p)),
    );
  }

  Widget _dueChip(String d) {
    final selected = dueBucket == d;
    return ChoiceChip(
      label: Text(d),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.primarySoft,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) =>
          setState(() => dueBucket = selected ? null : d),
    );
  }
}
