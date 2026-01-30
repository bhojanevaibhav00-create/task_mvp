import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_mvp/core/constants/app_colors.dart';
import 'package:task_mvp/core/providers/task_providers.dart';

class QuickAddTaskSheet extends ConsumerStatefulWidget {
  const QuickAddTaskSheet({super.key});

  @override
  ConsumerState<QuickAddTaskSheet> createState() =>
      _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState
    extends ConsumerState<QuickAddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int _priority = 1;
  DateTime? _dueDate;
  bool _showMore = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
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
          // ================= DRAG HANDLE =================
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ================= TITLE =================
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Add a task…',
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          // ================= QUICK CONTROLS =================
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip(
                icon: Icons.flag,
                label: _priorityLabel(),
                color: _priorityColor(),
                onTap: _cyclePriority,
              ),
              _chip(
                icon: Icons.calendar_today,
                label: _dueDate == null
                    ? 'Due date'
                    : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                onTap: _pickDueDate,
              ),
              _chip(
                icon: Icons.more_horiz,
                label: _showMore ? 'Less options' : 'More options',
                onTap: () => setState(() => _showMore = !_showMore),
              ),
            ],
          ),

          // ================= MORE OPTIONS =================
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.inputBackgroundDark
                      : AppColors.inputBackgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            crossFadeState: _showMore
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),

          const SizedBox(height: 20),

          // ================= ACTIONS =================
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
                  onPressed: _saveTask,
                  child: const Text('Add Task'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  Widget _chip({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color?.withOpacity(0.15) ??
              AppColors.chipBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }

  void _cyclePriority() {
    setState(() {
      _priority = _priority == 3 ? 1 : _priority + 1;
    });
  }

  String _priorityLabel() {
    switch (_priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Low';
    }
  }

  Color _priorityColor() {
    switch (_priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _dueDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _saveTask() async {
    if (_titleCtrl.text.trim().isEmpty) return;

    await ref.read(tasksProvider.notifier).addTask(
      _titleCtrl.text.trim(),
      _descCtrl.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
    );

    if (mounted) Navigator.pop(context);
  }
}