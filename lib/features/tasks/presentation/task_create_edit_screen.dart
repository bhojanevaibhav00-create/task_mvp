import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/providers/task_providers.dart';
import '../../../core/providers/collaboration_providers.dart';
import '../../../data/database/database.dart';
import '../../../core/constants/app_colors.dart';
import 'widgets/reminder_section.dart';

class TaskCreateEditScreen extends ConsumerStatefulWidget {
  final Task? task;
  final int? projectId;

  const TaskCreateEditScreen({super.key, this.task, this.projectId});

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
  int? _selectedAssigneeId;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task?.title ?? '');
    _descCtrl = TextEditingController(text: widget.task?.description ?? '');
    reminderEnabled = widget.task?.reminderEnabled ?? false;
    reminderAt = widget.task?.reminderAt;
    _priority = widget.task?.priority ?? 1;
    dueDate = widget.task?.dueDate;
    _selectedAssigneeId = widget.task?.assigneeId;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
    isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Column(
          children: [
            _buildCustomAppBar(isEdit),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.scaffoldDark
                      : const Color(0xFFF8F9FD),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _sectionLabel('TASK DETAILS'),
                      _inputGroup(isDark, textColor),

                      const SizedBox(height: 24),
                      _sectionLabel('ASSIGN TO'),
                      _assigneeSelector(isDark),

                      const SizedBox(height: 24),
                      _sectionLabel('PRIORITY'),
                      _prioritySelector(),

                      const SizedBox(height: 24),
                      _sectionLabel('SETTINGS'),
                      _settingsGroup(isDark, textColor),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 6,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text(
          'Save Task',
          style:
          TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: _saveTask,
      ),
    );
  }

  // ================= APP BAR =================
  Widget _buildCustomAppBar(bool isEdit) {
    return SafeArea(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Spacer(),
            Text(
              isEdit ? 'Edit Task' : 'New Task',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (isEdit)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.white),
                onPressed: () => _confirmDelete(context),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  // ================= INPUT GROUP =================
  Widget _inputGroup(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _titleCtrl,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor),
            decoration: InputDecoration(
              hintText: 'Task title',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
            ),
            validator: (v) =>
            v == null || v.isEmpty ? 'Title required' : null,
          ),
          const Divider(height: 24),
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Add details...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  // ================= ASSIGNEE =================
  Widget _assigneeSelector(bool isDark) {
    final pid = widget.projectId ?? widget.task?.projectId;
    if (pid == null) {
      return const Text('Select project first');
    }

    final membersAsync = ref.watch(projectMembersProvider(pid));

    return membersAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Failed to load members'),
      data: (members) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            isExpanded: true,
            value: _selectedAssigneeId,
            hint: const Text('Select assignee'),
            items: [
              const DropdownMenuItem<int?>(
                  value: null, child: Text('Unassigned')),
              ...members.map(
                    (m) => DropdownMenuItem<int?>(
                  value: m.member.userId,
                  child: Text(m.user.name),
                ),
              ),
            ],
            onChanged: (v) =>
                setState(() => _selectedAssigneeId = v),
          ),
        ),
      ),
    );
  }

  // ================= PRIORITY =================
  Widget _prioritySelector() {
    return Row(
      children: [
        _priorityBtn(1, 'Low', Colors.green),
        const SizedBox(width: 8),
        _priorityBtn(2, 'Med', Colors.orange),
        const SizedBox(width: 8),
        _priorityBtn(3, 'High', Colors.red),
      ],
    );
  }

  Widget _priorityBtn(int value, String label, Color color) {
    final selected = _priority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? color : Colors.grey),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= SETTINGS =================
  Widget _settingsGroup(bool isDark, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          ListTile(
            leading:
            const Icon(Icons.calendar_today, color: AppColors.primary),
            title: Text('Due Date',
                style:
                TextStyle(fontWeight: FontWeight.w600, color: textColor)),
            subtitle: Text(
              dueDate == null
                  ? 'Not set'
                  : '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
            ),
            onTap: _pickDueDate,
          ),
          const Divider(height: 1),
          ReminderSection(
            initialEnabled: reminderEnabled,
            initialTime: reminderAt,
            onChanged: (e, t) =>
                setState(() => {reminderEnabled = e, reminderAt = t}),
          ),
        ],
      ),
    );
  }

  // ================= SAVE / DELETE =================
  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(tasksProvider.notifier);

    if (widget.task == null) {
      await notifier.addTask(
        _titleCtrl.text,
        _descCtrl.text,
        priority: _priority,
        dueDate: dueDate,
        assigneeId: _selectedAssigneeId,
        projectId: widget.projectId,
      );
    } else {
      await notifier.updateTask(
        widget.task!.copyWith(
          title: _titleCtrl.text,
          description: drift.Value(_descCtrl.text),
          priority: drift.Value(_priority),
          dueDate: drift.Value(dueDate),
          reminderEnabled: reminderEnabled,
          reminderAt: drift.Value(reminderAt),
          assigneeId: drift.Value(_selectedAssigneeId),
        ),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
              const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (ok == true && widget.task != null) {
      await ref.read(tasksProvider.notifier).deleteTask(widget.task!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _pickDueDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => dueDate = d);
  }

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade500,
      ),
    ),
  );
}