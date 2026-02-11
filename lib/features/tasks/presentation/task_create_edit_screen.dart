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
    final textColor = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : const Color(0xFFF6F7FB),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Column(
          children: [
            _buildCustomAppBar(isEdit),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _sectionLabel('TASK DETAILS', isDark),
                      _inputGroup(isDark, textColor),
                      const SizedBox(height: 24),
                      
                      _sectionLabel('ASSIGN TO', isDark),
                      _assigneeSelector(isDark),
                      const SizedBox(height: 24),

                      _sectionLabel('PRIORITY', isDark),
                      _prioritySelector(isDark),
                      const SizedBox(height: 24),
                      
                      _sectionLabel('SETTINGS', isDark),
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

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text(
          'Save Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: _saveTask,
      ),
    );
  }

  // ================= HELPERS =================

  Widget _sectionLabel(String t, bool isDark) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white38 : Colors.grey.shade500,
      ),
    ),
  );

  Widget _buildCustomAppBar(bool isEdit) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
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
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () => _confirmDelete(context),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _inputGroup(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _titleCtrl,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            decoration: InputDecoration(
              hintText: 'Task title',
              hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400),
              border: InputBorder.none,
            ),
            validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
          ),
          Divider(height: 24, color: isDark ? Colors.white10 : Colors.grey.shade200),
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            style: TextStyle(fontSize: 16, color: textColor),
            decoration: InputDecoration(
              hintText: 'Add details...',
              hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _assigneeSelector(bool isDark) {
    final pid = widget.projectId ?? widget.task?.projectId;
    if (pid == null) return Text("Select a project first", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54));

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
            dropdownColor: isDark ? AppColors.cardDark : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            value: _selectedAssigneeId,
            hint: Text('Select assignee', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
            items: [
              DropdownMenuItem<int?>(value: null, child: Text('Unassigned', style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
              ...members.map((m) => DropdownMenuItem<int?>(
                value: m.member.userId,
                child: Text(m.user.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              )),
            ],
            onChanged: (v) => setState(() => _selectedAssigneeId = v),
          ),
        ),
      ),
    );
  }

  Widget _prioritySelector(bool isDark) {
    return Row(
      children: [
        _priorityBtn(1, 'Low', Colors.green, isDark),
        const SizedBox(width: 8),
        _priorityBtn(2, 'Med', Colors.orange, isDark),
        const SizedBox(width: 8),
        _priorityBtn(3, 'High', Colors.red, isDark),
      ],
    );
  }

  Widget _priorityBtn(int value, String label, Color color, bool isDark) {
    final selected = _priority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : (isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? color : (isDark ? Colors.white10 : Colors.grey)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : (isDark ? Colors.white38 : Colors.grey),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingsGroup(bool isDark, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today, color: AppColors.primary),
            title: Text('Due Date', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
            subtitle: Text(
              dueDate == null ? 'Not set' : '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
            trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.grey),
            onTap: _pickDueDate,
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
          Theme(
            data: Theme.of(context).copyWith(
              listTileTheme: ListTileThemeData(
                iconColor: AppColors.primary,
                titleTextStyle: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 16),
                subtitleTextStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
              ),
            ),
            child: ReminderSection(
              initialEnabled: reminderEnabled,
              initialTime: reminderAt,
              onChanged: (e, t) => setState(() => {reminderEnabled = e, reminderAt = t}),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ACTIONS =================

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(tasksProvider.notifier);
    final title = _titleCtrl.text.trim();
    final description = _descCtrl.text.trim();

    if (widget.task == null) {
      await notifier.addTask(
        title,
        description,
        priority: _priority,
        dueDate: dueDate,
        assigneeId: _selectedAssigneeId,
        projectId: widget.projectId,
      );
    } else {
      await notifier.updateTask(
        widget.task!.copyWith(
          title: title,
          description: drift.Value(description),
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
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Task?'),
        content: const Text('Are you sure you want to remove this task? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
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
}