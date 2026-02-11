import 'package:flutter/material.dart';
import 'package:task_mvp/core/constants/app_colors.dart';

typedef FilterApplyCallback = void Function(
    Map<String, bool> status,
    Map<String, bool> priority,
    Map<String, bool> tags,
    String? dueBucket,
    String? sort,
    );

void openFilterBottomSheet({
  required BuildContext context,
  required FilterApplyCallback onApply,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _FilterBottomSheet(onApply: onApply),
  );
}

class _FilterBottomSheet extends StatefulWidget {
  final FilterApplyCallback onApply;

  const _FilterBottomSheet({required this.onApply});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  Map<String, bool> statusFilters = {
    'todo': false,
    'done': false,
  };

  Map<String, bool> priorityFilters = {
    'low': false,
    'medium': false,
    'high': false,
  };

  void _clearFilters() {
    setState(() {
      statusFilters.updateAll((_, __) => false);
      priorityFilters.updateAll((_, __) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ================= STATUS =================
          const Text(
            'Status',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: statusFilters.keys.map((key) {
              return FilterChip(
                label: Text(key.toUpperCase()),
                selected: statusFilters[key]!,
                onSelected: (v) {
                  setState(() => statusFilters[key] = v);
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ================= PRIORITY =================
          const Text(
            'Priority',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: priorityFilters.keys.map((key) {
              return FilterChip(
                label: Text(key.toUpperCase()),
                selected: priorityFilters[key]!,
                onSelected: (v) {
                  setState(() => priorityFilters[key] = v);
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // ================= APPLY BUTTON =================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                widget.onApply(
                  statusFilters,
                  priorityFilters,
                  {},      // tags (future)
                  null,    // dueBucket (future)
                  null,    // sort (future)
                );
                Navigator.pop(context);
              },
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}