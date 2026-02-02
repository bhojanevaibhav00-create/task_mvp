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
  final int? taskId; // ✅ ADDED: For deep linking and GoRouter navigation
  final int? projectId; 

  const TaskCreateEditScreen({
    super.key, 
    this.task, 
    this.taskId, // ✅ ADDED
    this.projectId,
  });

  @override
  ConsumerState<TaskCreateEditScreen> createState() => _TaskCreateEditScreenState();
}

class _TaskCreateEditScreenState extends ConsumerState<TaskCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;

  bool reminderEnabled = false;
  DateTime? reminderAt;
  int _priority = 1;
  DateTime? dueDate;
  int? _selectedAssigneeId;
  
  // Track local task state if we fetch it via taskId
  Task? _fetchedTask;

  @override
  void initState() {
    super.initState();
    // 1. Initialize with provided task object if available
    final initialTask = widget.task;
    
    _titleCtrl = TextEditingController(text: initialTask?.title ?? '');
    _descCtrl = TextEditingController(text: initialTask?.description ?? '');
    reminderEnabled = initialTask?.reminderEnabled ?? false;
    reminderAt = initialTask?.reminderAt;
    _priority = initialTask?.priority ?? 1;
    dueDate = initialTask?.dueDate;
    _selectedAssigneeId = initialTask?.assigneeId;

    // 2. ✅ FIX: Fetch task data if only taskId is provided (GoRouter/Deep Link)
    if (widget.taskId != null && widget.task == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTaskById());
    }
  }

  /// Fetches task from database when opened via ID
  Future<void> _loadTaskById() async {
    final repo = ref.read(taskRepositoryProvider);
    final task = await repo.getTaskById(widget.taskId!);
    
    if (task != null && mounted) {
      setState(() {
        _fetchedTask = task;
        _titleCtrl.text = task.title;
        _descCtrl.text = task.description ?? '';
        reminderEnabled = task.reminderEnabled;
        reminderAt = task.reminderAt;
        _priority = task.priority ?? 1;
        dueDate = task.dueDate;
        _selectedAssigneeId = task.assigneeId;
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check both widget.task and our locally fetched task
    final currentTask = widget.task ?? _fetchedTask;
    final isEdit = currentTask != null;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Column(
          children: [
            _buildCustomAppBar(isEdit, currentTask),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FD),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildSectionLabel("TASK DETAILS"),
                      _buildInputGroup(),
                      const SizedBox(height: 24),
                      
                      _buildSectionLabel("ASSIGN TO"),
                      _buildAssigneeSelector(currentTask),
                      const SizedBox(height: 24),

                      _buildSectionLabel("PRIORITY"),
                      _buildPrioritySelector(),
                      const SizedBox(height: 24),
                      
                      _buildSectionLabel("SETTINGS"),
                      _buildSettingsGroup(),
                      const SizedBox(height: 100), 
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
        onPressed: () => _saveTask(currentTask),
        backgroundColor: AppColors.primary,
        elevation: 4,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text(
          "Save Task", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
        ),
      ),
    );
  }

  Widget _buildAssigneeSelector(Task? currentTask) {
    // Priority: widget.projectId -> currentTask.projectId -> null
    final pid = widget.projectId ?? currentTask?.projectId;
    
    if (pid == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: const Text("Linking to a project is required for assignment.", style: TextStyle(color: Colors.grey)),
      );
    }

    final membersAsync = ref.watch(projectMembersProvider(pid));

    return membersAsync.when(
      data: (members) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>( 
            isExpanded: true,
            value: _selectedAssigneeId,
            hint: const Text("Select Assignee"),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text("Unassigned")),
              ...members.map((m) => DropdownMenuItem<int?>(
                value: m.user.id,
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18),
                    const SizedBox(width: 8),
                    Text(m.user.name),
                  ],
                ),
              )),
            ],
            onChanged: (val) => setState(() => _selectedAssigneeId = val),
          ),
        ),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text("Error loading project members"),
    );
  }

  Widget _buildCustomAppBar(bool isEdit, Task? currentTask) {
    return SafeArea(
      bottom: false,
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
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (isEdit)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                onPressed: () => _confirmDelete(context, currentTask!),
              )
            else
              const SizedBox(width: 48), 
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildInputGroup() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            decoration: InputDecoration(
              hintText: 'Task Title', 
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Title required' : null,
          ),
          const Divider(height: 24),
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 16, color: Color(0xFF111827)),
            decoration: InputDecoration(
              hintText: 'Add details...', 
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: [
        _priorityButton(1, "Low", Colors.green),
        const SizedBox(width: 8),
        _priorityButton(2, "Med", Colors.orange),
        const SizedBox(width: 8),
        _priorityButton(3, "High", Colors.red),
      ],
    );
  }

  Widget _priorityButton(int value, String label, Color color) {
    final isSelected = _priority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? color : Colors.grey.shade200),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
            title: const Text("Due Date", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            subtitle: Text(dueDate == null ? "Not set" : "${dueDate!.day}/${dueDate!.month}/${dueDate!.year}"),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: _pickDueDate,
          ),
          const Divider(height: 1, indent: 60),
          ReminderSection(
            initialEnabled: reminderEnabled,
            initialTime: reminderAt,
            onChanged: (enabled, time) {
              setState(() {
                reminderEnabled = enabled;
                reminderAt = time;
              });
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: dueDate ?? DateTime.now(),
    );
    if (date != null) setState(() => dueDate = date);
  }

  Future<void> _confirmDelete(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Task?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(tasksProvider.notifier).deleteTask(task.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _saveTask(Task? currentTask) async {
    if (!_formKey.currentState!.validate()) return;
    
    final notifier = ref.read(tasksProvider.notifier);
    final title = _titleCtrl.text.trim();
    final description = _descCtrl.text.trim();

    if (currentTask == null) {
      await notifier.addTask(
        title, 
        description, 
        priority: _priority, 
        dueDate: dueDate,
        assigneeId: _selectedAssigneeId, 
        projectId: widget.projectId,
      );
    } else {
      final updated = currentTask.copyWith(
        title: title,
        description: drift.Value(description.isEmpty ? null : description),
        priority: drift.Value(_priority),
        dueDate: drift.Value(dueDate),
        reminderEnabled: reminderEnabled,
        reminderAt: drift.Value(reminderAt),
        assigneeId: drift.Value(_selectedAssigneeId),
      );
      await notifier.updateTask(updated);
    }
    if (mounted) Navigator.pop(context, true);
  }
}