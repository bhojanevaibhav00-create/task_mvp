import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:task_mvp/core/constants/app_colors.dart';


import '../../../core/providers/task_providers.dart';
import '../../../data/database/database.dart';
import 'widgets/reminder_section.dart';

class TaskCreateEditScreen extends ConsumerStatefulWidget {
  final Task? task;

  const TaskCreateEditScreen({super.key, this.task});

  @override
  ConsumerState<TaskCreateEditScreen> createState() =>
      _TaskCreateEditScreenState();
}

class _TaskCreateEditScreenState
    extends ConsumerState<TaskCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;

  bool reminderEnabled = false;
  DateTime? reminderAt;

  int _priority = 1;
  DateTime? dueDate;

  @override
  void initState() {
    super.initState();

    _titleCtrl = TextEditingController(text: widget.task?.title ?? '');
    _descCtrl = TextEditingController(text: widget.task?.description ?? '');

    reminderEnabled = widget.task?.reminderEnabled ?? false;
    reminderAt = widget.task?.reminderAt;

    _priority = widget.task?.priority ?? 1;
    dueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  final isEdit = widget.task != null;

  return Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    appBar: AppBar(
      title: Text(isEdit ? 'Edit Task' : 'Create Task'),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _saveTask,
      backgroundColor: Colors.blue,
      icon: const Icon(Icons.check),
      label: const Text("Save Task"),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          // MAIN CARD
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  TextFormField(
                    controller: _titleCtrl,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'What needs to be done?',
                      border: InputBorder.none,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Title required' : null,
                  ),

                  const Divider(),

                  // DESCRIPTION
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add details (optional)',
                      border: InputBorder.none,
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 20),

                  // PRIORITY
                  const Text(
                    "Priority",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _priorityChip(1, "Low", Colors.green),
                      _priorityChip(2, "Medium", Colors.orange),
                      _priorityChip(3, "High", Colors.red),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // DUE DATE
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, color: Colors.blue),
                    title: const Text("Due date"),
                    subtitle: Text(
                      dueDate == null
                          ? "Not set"
                          : "${dueDate!.day}/${dueDate!.month}/${dueDate!.year}",
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        initialDate: dueDate ?? DateTime.now(),
                      );
                      if (date != null) setState(() => dueDate = date);
                    },
                  ),

                  const SizedBox(height: 8),

                  // REMINDER
                  ReminderSection(
                    initialEnabled: reminderEnabled,
                    initialTime: reminderAt,
                    onChanged: (enabled, time) {
                      reminderEnabled = enabled;
                      reminderAt = time;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // ================= SAVE =================
  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (reminderEnabled && reminderAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select reminder time')),
      );
      return;
    }

    try {
      final notifier = ref.read(tasksProvider.notifier);

      if (widget.task == null) {
        await notifier.addTask(
          _titleCtrl.text.trim(),
          _descCtrl.text.trim(),
          priority: _priority,
          dueDate: dueDate,
        );
      } else {
        final updated = widget.task!.copyWith(
          title: _titleCtrl.text.trim(),
          description: drift.Value(
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          ),
          priority: drift.Value(_priority),
          dueDate: drift.Value(dueDate),
          reminderEnabled: reminderEnabled,
          reminderAt: drift.Value(reminderAt),
        );

        await notifier.updateTask(updated);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  Widget _priorityChip(int value, String label, Color color) {
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _priority == value,
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: _priority == value ? color : Colors.black,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) {
        setState(() => _priority = value);
      },
    ),
  );
}

}
