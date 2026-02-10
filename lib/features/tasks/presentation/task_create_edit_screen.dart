import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/task_providers.dart' hide notificationRepositoryProvider;
import '../../../core/providers/collaboration_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/providers/database_provider.dart';
import '../../../data/database/database.dart';
import 'widgets/reminder_section.dart';

class TaskCreateEditScreen extends ConsumerStatefulWidget {
  final Task? task;
  final int? taskId; 
  final int? projectId;

  const TaskCreateEditScreen({
    super.key,
    this.task,
    this.taskId,
    this.projectId,
  });

  @override
  ConsumerState<TaskCreateEditScreen> createState() => _TaskCreateEditScreenState();
}

class _TaskCreateEditScreenState extends ConsumerState<TaskCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;

  // State Variables
  bool reminderEnabled = false;
  DateTime? reminderAt;
  int _priority = 1;
  DateTime? _dueDate; 
  int? _selectedAssigneeId;
  Task? _fetchedTask;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final initialTask = widget.task;

    _titleCtrl = TextEditingController(text: initialTask?.title ?? '');
    _descCtrl = TextEditingController(text: initialTask?.description ?? '');
    reminderEnabled = initialTask?.reminderEnabled ?? false;
    reminderAt = initialTask?.reminderAt;
    _priority = initialTask?.priority ?? 1;
    _dueDate = initialTask?.dueDate;
    _selectedAssigneeId = initialTask?.assigneeId;

    if (widget.taskId != null && widget.task == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTaskById());
    }
  }

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
        _dueDate = task.dueDate;
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

  // ===========================================================================
  // ACTION LOGIC: DELETE & SAVE
  // ===========================================================================

  Future<void> _confirmDelete(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("Delete Task?", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
        content: Text("Are you sure you want to remove '${task.title}'? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep Task", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 🚀 FIX: Notification Call
        await ref.read(notificationRepositoryProvider).addNotification(
          title: "Task Deleted",
          message: "Task '${task.title}' was successfully removed.",
          type: "system",
          taskId: task.id,
          projectId: task.projectId,
        );

        // Perform Database Deletion
        await ref.read(tasksProvider.notifier).deleteTask(task.id);

        if (mounted) {
          context.pop(); // Return to previous screen
        }
        ref.invalidate(tasksProvider);
        ref.invalidate(filteredTasksProvider);

      } catch (e) {
        debugPrint("Error: $e");
      }
    }
  }

  Future<void> _saveTask(Task? currentTask) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final notifier = ref.read(tasksProvider.notifier);

    try {
      if (currentTask == null) {
        // CREATE MODE
        await notifier.addTask(
          _titleCtrl.text, 
          _descCtrl.text, 
          priority: _priority, 
          dueDate: _dueDate, 
          assigneeId: _selectedAssigneeId, 
          projectId: widget.projectId
        );
      } else {
        // EDIT MODE
        final updated = currentTask.copyWith(
          title: _titleCtrl.text,
          description: drift.Value(_descCtrl.text),
          priority: drift.Value(_priority),
          dueDate: drift.Value(_dueDate),
          reminderEnabled: reminderEnabled,
          reminderAt: drift.Value(reminderAt),
          assigneeId: drift.Value(_selectedAssigneeId),
        );
        await notifier.updateTask(updated);
      }
      if (mounted) context.pop();
    } catch (e) {
      debugPrint("Save failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // UI BUILDERS
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final currentTask = widget.task ?? _fetchedTask;
    final isEdit = currentTask != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildSectionLabel("TASK INFORMATION"),
                      _buildInputGroup(),
                      const SizedBox(height: 24),
                      
                      _buildSectionLabel("ASSIGNMENT"),
                      _buildAssigneeSelector(currentTask),
                      const SizedBox(height: 24),
                      
                      _buildSectionLabel("TASK PRIORITY"),
                      _buildPrioritySelector(),
                      const SizedBox(height: 24),
                      
                      _buildSectionLabel("SCHEDULE & REMINDERS"),
                      _buildSettingsGroup(),
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
        onPressed: _isLoading ? null : () => _saveTask(currentTask),
        backgroundColor: AppColors.primary,
        elevation: 6,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        label: _isLoading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(
              isEdit ? "Update Task" : "Create Task",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
            ),
      ),
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
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            const Spacer(),
            Text(
              isEdit ? 'Edit Task' : 'New Task',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
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

  Widget _buildInputGroup() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E)),
            decoration: InputDecoration(
              hintText: 'What needs to be done?',
              hintStyle: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.w500),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Title required' : null,
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6))),
          TextFormField(
            controller: _descCtrl,
            maxLines: 4,
            style: const TextStyle(fontSize: 16, color: Color(0xFF4B5563), height: 1.5),
            decoration: InputDecoration(
              hintText: 'Add description or notes...',
              hintStyle: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.w400),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssigneeSelector(Task? currentTask) {
    final pid = widget.projectId ?? currentTask?.projectId;
    if (pid == null) return const Text("Please select a project first", style: TextStyle(color: Colors.grey, fontSize: 12));
    
    final membersAsync = ref.watch(projectMembersProvider(pid));

    return membersAsync.when(
      data: (members) {
        // Ensure selected ID still exists in the project members
        final bool idExists = _selectedAssigneeId == null || members.any((m) => m.user.id == _selectedAssigneeId);
        final currentId = idExists ? _selectedAssigneeId : null;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              isExpanded: true,
              value: currentId,
              icon: const Icon(Icons.unfold_more_rounded, color: Colors.grey),
              items: [
                const DropdownMenuItem(value: null, child: Text("Unassigned", style: TextStyle(color: Colors.grey))),
                ...members.map((m) => DropdownMenuItem(
                  value: m.user.id, 
                  child: Text(m.user.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1C1E)))
                )),
              ],
              onChanged: (val) => setState(() => _selectedAssigneeId = val),
            ),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text("Error loading members"),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: [
        _priorityButton(1, "Low", const Color(0xFF34D399)),
        const SizedBox(width: 12),
        _priorityButton(2, "Medium", const Color(0xFFFB923C)),
        const SizedBox(width: 12),
        _priorityButton(3, "High", const Color(0xFFF87171)),
      ],
    );
  }

  Widget _priorityButton(int value, String label, Color color) {
    final isSelected = _priority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isSelected ? color : Colors.grey.shade100, width: 2),
            boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: Center(
            child: Text(
              label, 
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade500, 
                fontWeight: FontWeight.w900, 
                fontSize: 13
              )
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
            ),
            title: const Text("Due Date", style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
            subtitle: Text(_dueDate == null ? "Set a deadline" : "${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}"),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: _pickDueDate,
          ),
          const Divider(height: 1, indent: 70, color: Color(0xFFF3F4F6)),
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _dueDate ?? DateTime.now(),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}