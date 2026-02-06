import 'package:flutter/material.dart';
import '../../../../data/models/tag_model.dart';
import '../../../../core/constants/app_colors.dart';

/// Entry point to open the Filter Bottom Sheet
void openFilterBottomSheet({
  required BuildContext context,
  required List<Tag> allTags,
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
    backgroundColor: Colors.transparent, 
    builder: (_) => _FilterSheet(
      allTags: allTags,
      initialStatus: statusFilters,
      initialPriority: priorityFilters,
      initialTags: tagFilters,
      initialDueBucket: dueBucket,
      initialSort: sort,
      onApply: onApply,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
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

  const _FilterSheet({
    super.key,
    required this.allTags,
    required this.initialStatus,
    required this.initialPriority,
    required this.initialTags,
    required this.initialDueBucket,
    required this.initialSort,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<String> status;
  late Set<int> priority;
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
    // ✅ FORCED PREMIUM WHITE THEME CONSTANTS
    const scaffoldBg = Color(0xFFF8F9FD); 
    const sectionBg = Colors.white;
    const primaryTextColor = Color(0xFF1A1C1E); // Slate 900
    const chipDefaultBg = Color(0xFFF1F5F9); // Light Slate 100

    return Container(
      decoration: const BoxDecoration(
        color: scaffoldBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
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
              _header(primaryTextColor),
              const SizedBox(height: 24),

              // Status Section
              _cardSection("STATUS", ["TODO", "INPROGRESS", "DONE", "REVIEW"].map((s) => 
                _statusChip(s, chipDefaultBg)).toList(), sectionBg),
              
              // Priority Section
              _cardSection("PRIORITY", [1, 2, 3].map((p) => 
                _priorityChip(p, chipDefaultBg)).toList(), sectionBg),
              
              // Due Date Section
              _cardSection("DUE DATE", ["Today", "Overdue", "Upcoming"].map((d) => 
                _dueChip(d, chipDefaultBg)).toList(), sectionBg),
              
              if (widget.allTags.isNotEmpty)
                _cardSection("TAGS", widget.allTags.map((t) => 
                  _tagChip(t, chipDefaultBg)).toList(), sectionBg),

              const SizedBox(height: 24),
              _actions(primaryTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 48, height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _header(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Filter Tasks",
          style: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.w900, 
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        TextButton(
          onPressed: () => setState(() {
            status.clear(); priority.clear(); tags.clear(); dueBucket = null;
          }),
          child: const Text("Reset All", 
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _cardSection(String title, List<Widget> chips, Color bgColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, 
            style: const TextStyle(
              fontWeight: FontWeight.w900, 
              fontSize: 10, 
              letterSpacing: 1.5,
              color: Color(0xFF94A3B8), // Slate 400
            )
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }

  Widget _themedChoiceChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
    required Color activeColor,
    required Color defaultBg,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      pressElevation: 0,
      elevation: 0,
      backgroundColor: defaultBg,
      selectedColor: activeColor.withOpacity(0.08), // ✅ Soft tinted background
      side: BorderSide(
        color: selected ? activeColor : Colors.transparent, // ✅ Colored border when selected
        width: 1.5,
      ),
      labelStyle: TextStyle(
        color: selected ? activeColor : const Color(0xFF64748B), // Slate 500
        fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      showCheckmark: false, // ✅ Cleaner premium look without the checkmark
    );
  }

  Widget _statusChip(String s, Color defaultBg) {
    return _themedChoiceChip(
      label: s,
      selected: status.contains(s),
      defaultBg: defaultBg,
      activeColor: AppColors.primary,
      onSelected: (_) => setState(() => status.contains(s) ? status.remove(s) : status.add(s)),
    );
  }

  Widget _priorityChip(int p, Color defaultBg) {
    final labels = {1: "LOW", 2: "MEDIUM", 3: "HIGH"};
    final colors = {1: Colors.green, 2: const Color(0xFFF59E0B), 3: const Color(0xFFEF4444)};
    return _themedChoiceChip(
      label: labels[p]!,
      selected: priority.contains(p),
      defaultBg: defaultBg,
      activeColor: colors[p]!,
      onSelected: (_) => setState(() => priority.contains(p) ? priority.remove(p) : priority.add(p)),
    );
  }

  Widget _dueChip(String d, Color defaultBg) {
    return _themedChoiceChip(
      label: d,
      selected: dueBucket == d,
      defaultBg: defaultBg,
      activeColor: const Color(0xFF3B82F6),
      onSelected: (_) => setState(() => dueBucket = (dueBucket == d) ? null : d),
    );
  }

  Widget _tagChip(Tag t, Color defaultBg) {
    return _themedChoiceChip(
      label: t.label,
      selected: tags.contains(t),
      defaultBg: defaultBg,
      activeColor: AppColors.primary,
      onSelected: (_) => setState(() => tags.contains(t) ? tags.remove(t) : tags.add(t)),
    );
  }

  Widget _actions(Color textColor) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Cancel", 
              style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              widget.onApply(status, priority, tags, dueBucket, sort);
              Navigator.pop(context);
            },
            child: const Text("Apply Filters", 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}