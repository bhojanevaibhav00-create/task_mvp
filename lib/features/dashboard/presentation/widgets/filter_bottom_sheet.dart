import 'package:flutter/material.dart';
import '../../../../data/database/database.dart' as db;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1A1C1E);
    final scaffoldBg = isDark ? AppColors.surfaceDark : const Color(0xFFF8F9FD);
    final sectionBg = isDark ? AppColors.cardDark : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
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
              _header(isDark, primaryTextColor),
              const SizedBox(height: 24),

              _cardSection("STATUS", ["todo", "inProgress", "done", "review"].map((s) => _statusChip(s, isDark)).toList(), isDark, sectionBg),
              _cardSection("PRIORITY", [1, 2, 3].map((p) => _priorityChip(p, isDark)).toList(), isDark, sectionBg),
              _cardSection("DUE DATE", ["Today", "Overdue", "Upcoming"].map((d) => _dueChip(d, isDark)).toList(), isDark, sectionBg),
              
              if (widget.allTags.isNotEmpty)
                _cardSection("TAGS", widget.allTags.map((t) => _tagChip(t, isDark)).toList(), isDark, sectionBg),

              const SizedBox(height: 24),
              _actions(isDark, primaryTextColor),
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

  Widget _header(bool isDark, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Filter Tasks",
          style: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.w900, 
            color: textColor
          ),
        ),
        TextButton(
          onPressed: () => setState(() {
            status.clear(); priority.clear(); tags.clear(); dueBucket = null;
          }),
          child: const Text("Reset All", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _cardSection(String title, List<Widget> chips, bool isDark, Color bgColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, 
            style: TextStyle(
              fontWeight: FontWeight.w800, 
              fontSize: 11, 
              letterSpacing: 1.2,
              color: isDark ? Colors.white38 : Colors.blueGrey.shade300
            )
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: chips),
        ],
      ),
    );
  }

  // ✅ Helper for ChoiceChips to ensure color consistency
  Widget _themedChoiceChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
    required Color activeColor,
    required bool isDark,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      pressElevation: 0,
      backgroundColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
      selectedColor: activeColor.withOpacity(0.15),
      side: BorderSide(
        color: selected ? activeColor : Colors.transparent,
        width: 1.5,
      ),
      labelStyle: TextStyle(
        color: selected ? activeColor : (isDark ? Colors.white70 : const Color(0xFF475569)),
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _statusChip(String s, bool isDark) {
    return _themedChoiceChip(
      label: s.toUpperCase(),
      selected: status.contains(s),
      isDark: isDark,
      activeColor: AppColors.primary,
      onSelected: (_) => setState(() => status.contains(s) ? status.remove(s) : status.add(s)),
    );
  }

  Widget _priorityChip(int p, bool isDark) {
    final labels = {1: "LOW", 2: "MEDIUM", 3: "HIGH"};
    final colors = {1: Colors.green, 2: Colors.orange, 3: Colors.red};
    return _themedChoiceChip(
      label: labels[p]!,
      selected: priority.contains(p),
      isDark: isDark,
      activeColor: colors[p]!,
      onSelected: (_) => setState(() => priority.contains(p) ? priority.remove(p) : priority.add(p)),
    );
  }

  Widget _dueChip(String d, bool isDark) {
    return _themedChoiceChip(
      label: d,
      selected: dueBucket == d,
      isDark: isDark,
      activeColor: Colors.blue,
      onSelected: (_) => setState(() => dueBucket = (dueBucket == d) ? null : d),
    );
  }

  Widget _tagChip(Tag t, bool isDark) {
    return _themedChoiceChip(
      label: t.label,
      selected: tags.contains(t),
      isDark: isDark,
      activeColor: AppColors.primary,
      onSelected: (_) => setState(() => tags.contains(t) ? tags.remove(t) : tags.add(t)),
    );
  }

  Widget _actions(bool isDark, Color textColor) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text("Cancel", style: TextStyle(color: textColor.withOpacity(0.6), fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: () {
              widget.onApply(status, priority, tags, dueBucket, sort);
              Navigator.pop(context);
            },
            child: const Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}