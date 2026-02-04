import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/enums.dart';

class QuickAddTaskSheet extends ConsumerStatefulWidget {
  const QuickAddTaskSheet({super.key});

  @override
  ConsumerState<QuickAddTaskSheet> createState() =>
      _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState extends ConsumerState<QuickAddTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  Priority? priority;
  DateTime? dueDate;
  DateTime? reminderDate;

  bool showMore = false;
  bool tagsOpen = false;
  bool descOpen = false;
  bool reminderOpen = false;

  final tags = ['Work', 'Personal', 'Urgent', 'Bug'];
  final selectedTags = <String>{};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// DRAG HANDLE
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          /// TITLE INPUT
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Task title',
              hintStyle: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          /// QUICK CONTROLS
          Row(
            children: [
              _quickChip(
                icon: Icons.flag,
                label: priority?.name ?? 'Priority',
                active: priority != null,
                onTap: _pickPriority,
              ),
              const SizedBox(width: 12),
              _quickChip(
                icon: Icons.calendar_today,
                label: dueDate == null
                    ? 'Due date'
                    : '${dueDate!.day}/${dueDate!.month}',
                active: dueDate != null,
                onTap: _pickDate,
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  showMore ? Icons.expand_less : Icons.expand_more,
                ),
                onPressed: () =>
                    setState(() => showMore = !showMore),
              ),
            ],
          ),

          /// MORE OPTIONS
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: showMore
                ? Column(
              children: [
                const Divider(),

                /// TAGS
                _expandTile(
                  icon: Icons.label_outline,
                  label: 'Tags',
                  expanded: tagsOpen,
                  onTap: () =>
                      setState(() => tagsOpen = !tagsOpen),
                  child: Wrap(
                    spacing: 8,
                    children: tags.map((tag) {
                      final selected =
                      selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: selected,
                        selectedColor:
                        AppColors.primary.withOpacity(0.15),
                        onSelected: (_) {
                          setState(() {
                            selected
                                ? selectedTags.remove(tag)
                                : selectedTags.add(tag);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                /// DESCRIPTION
                _expandTile(
                  icon: Icons.notes_outlined,
                  label: 'Description',
                  expanded: descOpen,
                  onTap: () =>
                      setState(() => descOpen = !descOpen),
                  child: TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add description',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                /// REMINDER
                _expandTile(
                  icon: Icons.notifications_none,
                  label: 'Reminder',
                  expanded: reminderOpen,
                  onTap: () => setState(
                          () => reminderOpen = !reminderOpen),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        reminderDate == null
                            ? 'Not set'
                            : '${reminderDate!.day}/${reminderDate!.month}',
                      ),
                      Switch(
                        value: reminderDate != null,
                        activeColor: AppColors.primary,
                        onChanged: (v) async {
                          if (!v) {
                            setState(
                                    () => reminderDate = null);
                            return;
                          }
                          final picked =
                          await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                            initialDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(
                                    () => reminderDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 20),

          /// ACTIONS
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (_titleController.text.trim().isEmpty) return;
                  Navigator.pop(context);
                },
                child: const Text(
                  'Add Task',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ================= HELPERS =================

  Widget _quickChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.primary
                : Colors.grey.shade400,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color:
                active ? AppColors.primary : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: active
                    ? AppColors.primary
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expandTile({
    required IconData icon,
    required String label,
    required bool expanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title: Text(label),
          trailing: Icon(
              expanded ? Icons.expand_less : Icons.expand_more),
          onTap: onTap,
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 12),
            child: child,
          ),
        const Divider(),
      ],
    );
  }

  void _pickPriority() async {
    final result = await showModalBottomSheet<Priority>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: Priority.values
            .map(
              (p) => ListTile(
            title: Text(p.name),
            onTap: () => Navigator.pop(context, p),
          ),
        )
            .toList(),
      ),
    );
    if (result != null) {
      setState(() => priority = result);
    }
  }

  void _pickDate() async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (result != null) {
      setState(() => dueDate = result);
    }
  }
}
