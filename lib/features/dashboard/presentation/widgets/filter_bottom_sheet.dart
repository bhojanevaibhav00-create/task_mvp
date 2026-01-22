import 'package:flutter/material.dart';
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
    builder: (_) {
      return _FilterBottomSheet(
        allTags: allTags,
        initialStatus: statusFilters,
        initialPriority: priorityFilters,
        initialTags: tagFilters,
        initialDueBucket: dueBucket,
        initialSort: sort,
        onApply: onApply,
      );
    },
  );
}

class _FilterBottomSheet extends StatefulWidget {
  final List<Tag> allTags;
  final Set<TaskStatus> initialStatus;
  final Set<Priority> initialPriority;
  final Set<Tag> initialTags;
  final String? initialDueBucket;
  final String? initialSort;
  final Function(
      Set<TaskStatus>,
      Set<Priority>,
      Set<Tag>,
      String?,
      String?,
      ) onApply;

  const _FilterBottomSheet({
    required this.allTags,
    required this.initialStatus,
    required this.initialPriority,
    required this.initialTags,
    required this.initialDueBucket,
    required this.initialSort,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late Set<TaskStatus> status;
  late Set<Priority> priority;
  late Set<Tag> tags;
  String? dueBucket;
  String? sort;

  @override
  void initState() {
    super.initState();
    status = {...widget.initialStatus};
    priority = {...widget.initialPriority};
    tags = {...widget.initialTags};
    dueBucket = widget.initialDueBucket;
    sort = widget.initialSort;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
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
            const SizedBox(height: 12),
            _header(),
            const SizedBox(height: 20),

            _cardSection("Status", TaskStatus.values.map(_statusChip).toList()),
            _cardSection("Priority", Priority.values.map(_priorityChip).toList()),
            _cardSection("Due", ["Today", "Overdue", "Next 7 Days"].map(_dueChip).toList()),
            _cardSection("Tags", widget.allTags.map(_tagChip).toList()),

            const SizedBox(height: 20),
            _actions(),
          ],
        ),
      ),
    );
  }

  // ================= UI COMPONENTS =================

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

  Widget _header() {
    return Row(
      children: [
        const Text(
          "Filters",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            setState(() {
              status.clear();
              priority.clear();
              tags.clear();
              dueBucket = null;
              sort = null;
            });
          },
          child: const Text("Clear all"),
        ),
      ],
    );
  }

  Widget _cardSection(String title, List<Widget> chips) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: chips),
        ],
      ),
    );
  }

  Widget _statusChip(TaskStatus s) {
    final selected = status.contains(s);
    return ChoiceChip(
      label: Text(_statusLabel(s)),
      selected: selected,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? Theme.of(context).primaryColor : Colors.black87,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => setState(() {
        selected ? status.remove(s) : status.add(s);
      }),
    );
  }

  Widget _priorityChip(Priority p) {
    final selected = priority.contains(p);
    return ChoiceChip(
      label: Text(p.name.toUpperCase()),
      selected: selected,
      selectedColor: Colors.orange.withOpacity(0.15),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? Colors.orange : Colors.black87,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => setState(() {
        selected ? priority.remove(p) : priority.add(p);
      }),
    );
  }

  Widget _dueChip(String d) {
    final selected = dueBucket == d;
    return ChoiceChip(
      label: Text(d),
      selected: selected,
      selectedColor: Colors.blue.withOpacity(0.15),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? Colors.blue : Colors.black87,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => setState(() {
        dueBucket = selected ? null : d;
      }),
    );
  }

  Widget _tagChip(Tag t) {
    final selected = tags.contains(t);
    return ChoiceChip(
      label: Text(t.label),
      selected: selected,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? Theme.of(context).primaryColor : Colors.black87,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => setState(() {
        selected ? tags.remove(t) : tags.add(t);
      }),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              widget.onApply(status, priority, tags, dueBucket, sort);
              Navigator.pop(context);
            },
            child: const Text("Apply Filters"),
          ),
        ),
      ],
    );
  }

  String _statusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return "To Do";
      case TaskStatus.inProgress:
        return "In Progress";
      case TaskStatus.done:
        return "Done";
      case TaskStatus.review:
        return "Review";
    }
  }
}
