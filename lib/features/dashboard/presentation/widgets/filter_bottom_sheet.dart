import 'package:flutter/material.dart';
// 🚀 Importing the database model for TaskStatus and Priority
import '../../../../data/database/database.dart' as db;
import '../../../../data/models/tag_model.dart';
import '../../../../core/constants/app_colors.dart';

void openFilterBottomSheet({
  required BuildContext context,
  required List<Tag> allTags,
  // 🚀 Changed TaskStatus to use database enum
  required Set<String> statusFilters, 
  required Set<int> priorityFilters,
  required Set<Tag> tagFilters,
  required String? dueBucket,
  required String? sort,
  required Function(
      Set<String>,
      Set<int>,
      Set<Tag>,
      String?,
      String?,
      ) onApply,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
  final Set<String> initialStatus;
  final Set<int> initialPriority;
  final Set<Tag> initialTags;
  final String? initialDueBucket;
  final String? initialSort;
  final Function(
      Set<String>,
      Set<int>,
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
  late Set<String> status;
  late Set<int> priority;
  late Set<Tag> tags;
  String? dueBucket;
  String? sort;

  @override
  void initState() {
    super.initState();
    // Synchronizing with initial values passed from the parent
    status = {...widget.initialStatus};
    priority = {...widget.initialPriority};
    tags = {...widget.initialTags};
    dueBucket = widget.initialDueBucket;
    sort = widget.initialSort;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dragHandle(),
            const SizedBox(height: 16),
            _header(),
            const SizedBox(height: 24),

            // Status Filter Section
            _cardSection("Status", ["todo", "inProgress", "done", "review"].map(_statusChip).toList()),
            
            // Priority Filter Section (Using DB int values)
            _cardSection("Priority", [1, 2, 3].map(_priorityChip).toList()),
            
            // Due Date Filter Section
            _cardSection("Due Date", ["Today", "Overdue", "Upcoming"].map(_dueChip).toList()),
            
            // Dynamic Tags Filter Section
            _cardSection("Tags", widget.allTags.map(_tagChip).toList()),

            const SizedBox(height: 24),
            _actions(),
          ],
        ),
      ),
    );
  }

  // ================= PREMIUM UI COMPONENTS =================

  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Filter Tasks",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        TextButton(
          onPressed: () => setState(() {
            status.clear();
            priority.clear();
            tags.clear();
            dueBucket = null;
          }),
          child: const Text("Reset All", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _cardSection(String title, List<Widget> chips) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }

  Widget _statusChip(String s) {
    final isSelected = status.contains(s);
    return ChoiceChip(
      label: Text(s.toUpperCase()),
      selected: isSelected,
      onSelected: (_) => setState(() => isSelected ? status.remove(s) : status.add(s)),
      selectedColor: AppColors.primary.withOpacity(0.1),
      labelStyle: TextStyle(color: isSelected ? AppColors.primary : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _priorityChip(int p) {
    final isSelected = priority.contains(p);
    final labels = {1: "LOW", 2: "MEDIUM", 3: "HIGH"};
    final colors = {1: Colors.green, 2: Colors.orange, 3: Colors.red};

    return ChoiceChip(
      label: Text(labels[p]!),
      selected: isSelected,
      onSelected: (_) => setState(() => isSelected ? priority.remove(p) : priority.add(p)),
      selectedColor: colors[p]!.withOpacity(0.1),
      labelStyle: TextStyle(color: isSelected ? colors[p] : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _dueChip(String d) {
    final isSelected = dueBucket == d;
    return ChoiceChip(
      label: Text(d),
      selected: isSelected,
      onSelected: (_) => setState(() => dueBucket = isSelected ? null : d),
      selectedColor: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _tagChip(Tag t) {
    final isSelected = tags.contains(t);
    return ChoiceChip(
      label: Text(t.label),
      selected: isSelected,
      onSelected: (_) => setState(() => isSelected ? tags.remove(t) : tags.add(t)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: () {
              widget.onApply(status, priority, tags, dueBucket, sort);
              Navigator.pop(context);
            },
            child: const Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}