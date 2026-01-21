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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 16),

          _section("Status", TaskStatus.values.map(_statusChip).toList()),
          _section("Priority", Priority.values.map(_priorityChip).toList()),
          _section("Due", ["Today", "Overdue", "Next 7 Days"].map(_dueChip).toList()),
          _section("Tags", widget.allTags.map(_tagChip).toList()),

          const SizedBox(height: 24),
          _actions(),
        ],
      ),
    );
  }

  // ================= UI PARTS =================

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Filters", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          child: const Text("Clear"),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _statusChip(TaskStatus s) {
    final selected = status.contains(s);
    return FilterChip(
      label: Text(_statusLabel(s)),
      selected: selected,
      onSelected: (_) => setState(() {
        selected ? status.remove(s) : status.add(s);
      }),
    );
  }

  Widget _priorityChip(Priority p) {
    final selected = priority.contains(p);
    return FilterChip(
      label: Text(p.name.toUpperCase()),
      selected: selected,
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
      onSelected: (_) => setState(() {
        dueBucket = selected ? null : d;
      }),
    );
  }

  Widget _tagChip(Tag t) {
    final selected = tags.contains(t);
    return FilterChip(
      label: Text(t.label),
      selected: selected,
      onSelected: (_) => setState(() {
        selected ? tags.remove(t) : tags.add(t);
      }),
    );
  }

  Widget _actions() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          widget.onApply(status, priority, tags, dueBucket, sort);
          Navigator.pop(context);
        },
        child: const Text("Apply Filters"),
      ),
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
