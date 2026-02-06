import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/task_providers.dart';
import '../../../../data/models/enums.dart';

class QuickAddTaskSheet extends ConsumerStatefulWidget {
  const QuickAddTaskSheet({super.key});

  @override
  ConsumerState<QuickAddTaskSheet> createState() => _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState extends ConsumerState<QuickAddTaskSheet> {
  // ✅ Merged Controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  Priority? _priority;
  DateTime? _dueDate;
  DateTime? _reminderDate;

  bool _showMore = false;
  bool _tagsOpen = false;
  bool _descOpen = false;
  bool _reminderOpen = false;

  final _availableTags = ['Work', 'Personal', 'Urgent', 'Bug'];
  final _selectedTags = <String>{};

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const backgroundColor = Colors.white; // ✅ Forced Premium White Theme
    const primaryText = Color(0xFF1A1C1E);

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
          /// DRAG HANDLE
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          /// TITLE INPUT
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'What needs to be done?',
              hintStyle: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white54 : Colors.black26,
              ),
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w700, 
              color: primaryText
            ),
          ),

          const SizedBox(height: 16),

          /// QUICK CONTROLS
          Row(
            children: [
              _quickChip(
                icon: Icons.flag_rounded,
                label: _priority?.name.toUpperCase() ?? 'PRIORITY',
                active: _priority != null,
                onTap: _pickPriority,
                color: _getPriorityColor(),
              ),
              const SizedBox(width: 12),
              _quickChip(
                icon: Icons.calendar_today_rounded,
                label: _dueDate == null
                    ? 'DUE DATE'
                    : '${_dueDate!.day}/${_dueDate!.month}',
                active: _dueDate != null,
                onTap: _pickDate,
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showMore ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primary,
                ),
                onPressed: () => setState(() => _showMore = !_showMore),
              ),
            ],
          ),

          /// MORE OPTIONS (Vaishnavi's Expandable UI)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _showMore
                ? Column(
                    children: [
                      const Divider(height: 32),

                      /// DESCRIPTION
                      _expandTile(
                        icon: Icons.notes_rounded,
                        label: 'Description',
                        expanded: _descOpen,
                        onTap: () => setState(() => _descOpen = !_descOpen),
                        child: TextField(
                          controller: _descCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Add extra details...',
                            filled: true,
                            fillColor: const Color(0xFFF8F9FD),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      /// TAGS
                      _expandTile(
                        icon: Icons.local_offer_outlined,
                        label: 'Tags',
                        expanded: _tagsOpen,
                        onTap: () => setState(() => _tagsOpen = !_tagsOpen),
                        child: Wrap(
                          spacing: 8,
                          children: _availableTags.map((tag) {
                            final selected = _selectedTags.contains(tag);
                            return FilterChip(
                              label: Text(tag),
                              selected: selected,
                              onSelected: (val) {
                                setState(() {
                                  val ? _selectedTags.add(tag) : _selectedTags.remove(tag);
                                });
                              },
                              selectedColor: AppColors.primary.withOpacity(0.1),
                              checkmarkColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            );
                          }).toList(),
                        ),
                      ),

                      /// REMINDER
                      _expandTile(
                        icon: Icons.notifications_none_rounded,
                        label: 'Reminder',
                        expanded: _reminderOpen,
                        onTap: () => setState(() => _reminderOpen = !_reminderOpen),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _reminderDate == null
                                  ? 'Not set'
                                  : '${_reminderDate!.day}/${_reminderDate!.month} at ${_reminderDate!.hour}:${_reminderDate!.minute}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Switch(
                              value: _reminderDate != null,
                              activeColor: AppColors.primary,
                              onChanged: (v) => _pickReminder(v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          /// ACTIONS
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _saveTask,
                child: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.w900)),
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
    Color? color,
  }) {
    final activeColor = color ?? AppColors.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? activeColor : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? activeColor : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: active ? activeColor : Colors.grey.shade600,
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
          leading: Icon(icon, color: Colors.slate),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 20),
          onTap: onTap,
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 16),
            child: child,
          ),
      ],
    );
  }

  Color? _getPriorityColor() {
    if (_priority == Priority.high) return Colors.red;
    if (_priority == Priority.medium) return Colors.orange;
    if (_priority == Priority.low) return Colors.green;
    return null;
  }

  void _pickPriority() async {
    final result = await showModalBottomSheet<Priority>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: Priority.values.map((p) => ListTile(
          leading: Icon(Icons.flag_rounded, color: p == Priority.high ? Colors.red : p == Priority.medium ? Colors.orange : Colors.green),
          title: Text(p.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () => Navigator.pop(context, p),
        )).toList(),
      ),
    );
    if (result != null) setState(() => _priority = result);
  }

  void _pickDate() async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _dueDate ?? DateTime.now(),
    );
    if (result != null) setState(() => _dueDate = result);
  }

  void _pickReminder(bool enable) async {
    if (!enable) {
      setState(() => _reminderDate = null);
      return;
    }
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (date != null) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null) {
        setState(() => _reminderDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
      }
    }
  }

  Future<void> _saveTask() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    await ref.read(tasksProvider.notifier).addTask(
      title,
      _descCtrl.text.trim(),
      priority: _priority?.index ?? 1, // Default to Medium if not set
      dueDate: _dueDate,
    );

    if (mounted) Navigator.pop(context);
  }
}