import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../data/database/database.dart' as db;
import '../../../../core/providers/task_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/task_filters.dart';
import '../../../../data/repositories/task_repository.dart'; // ✅ Added for TaskWithAssignee type

enum SmartListType { myDay, important, planned, all }

class SmartListScreen extends ConsumerStatefulWidget {
  final String title;
  final IconData icon;
  final SmartListType type;

  const SmartListScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.type,
  });

  @override
  ConsumerState<SmartListScreen> createState() => _SmartListScreenState();
}

class _SmartListScreenState extends ConsumerState<SmartListScreen> {
  String? _statusFilter;
  int? _priorityFilter;
  DateTime? _dueDateFilter;

  @override
  Widget build(BuildContext context) {
    // 🚀 WATCHING: Live stream of TaskWithAssignee wrappers
    final tasksAsync = ref.watch(filteredTasksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Row(
          children: [
            Icon(widget.icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _hasFilters ? AppColors.primary : Colors.grey,
            ),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            onPressed: () => _showAddTaskSheet(context, ref),
            icon: const Icon(
              Icons.add_circle_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (List<TaskWithAssignee> wrappers) {
          // ✅ 1. Apply Smart Filtering on the wrappers
          final filteredWrappers = _applySmartFilter(wrappers);

          // ✅ 2. Unwrap for dynamic filtering logic if necessary, or filter wrappers directly
          // Using a modified filter approach to preserve assignee data
          final finalWrappers = filteredWrappers.where((w) {
            bool matches = true;
            if (_statusFilter != null)
              matches &= w.task.status == _statusFilter;
            if (_priorityFilter != null)
              matches &= w.task.priority == _priorityFilter;
            if (_dueDateFilter != null) {
              matches &=
                  w.task.dueDate?.year == _dueDateFilter!.year &&
                  w.task.dueDate?.month == _dueDateFilter!.month &&
                  w.task.dueDate?.day == _dueDateFilter!.day;
            }
            return matches;
          }).toList();

          if (finalWrappers.isEmpty) {
            return const Center(child: Text("No tasks in this list."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: finalWrappers.length,
            itemBuilder: (context, index) {
              final item = finalWrappers[index];
              return _TaskCard(
                task: item.task,
                assigneeName: item.assignee?.name, // ✅ Pass member name
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  List<TaskWithAssignee> _applySmartFilter(List<TaskWithAssignee> wrappers) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (widget.type) {
      case SmartListType.myDay:
        return wrappers
            .where(
              (w) =>
                  w.task.dueDate != null &&
                  w.task.dueDate!.year == today.year &&
                  w.task.dueDate!.month == today.month &&
                  w.task.dueDate!.day == today.day,
            )
            .toList();
      case SmartListType.important:
        return wrappers.where((w) => w.task.priority == 3).toList();
      case SmartListType.planned:
        return wrappers.where((w) => w.task.dueDate != null).toList();
      case SmartListType.all:
      default:
        return wrappers;
    }
  }

  void _showAddTaskSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    DateTime? selectedDate = (widget.type == SmartListType.myDay)
        ? DateTime.now()
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Enter task name...",
                border: InputBorder.none,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.calendar_month,
                    color: AppColors.primary,
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) selectedDate = picked;
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    if (controller.text.isEmpty) return;
                    ref
                        .read(tasksProvider.notifier)
                        .addTask(
                          controller.text,
                          "",
                          dueDate: selectedDate,
                          priority: (widget.type == SmartListType.important)
                              ? 3
                              : 1,
                        );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Save Task",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasFilters =>
      _statusFilter != null ||
      _priorityFilter != null ||
      _dueDateFilter != null;

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter Tasks",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text("Status"),
              Wrap(
                spacing: 8,
                children: [
                  _filterChip(
                    "All",
                    _statusFilter == null,
                    () => setModalState(() => _statusFilter = null),
                  ),
                  _filterChip(
                    "Todo",
                    _statusFilter == 'todo',
                    () => setModalState(() => _statusFilter = 'todo'),
                  ),
                  _filterChip(
                    "Done",
                    _statusFilter == 'done',
                    () => setModalState(() => _statusFilter = 'done'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text("Priority"),
              Wrap(
                spacing: 8,
                children: [
                  _filterChip(
                    "All",
                    _priorityFilter == null,
                    () => setModalState(() => _priorityFilter = null),
                  ),
                  _filterChip(
                    "Low",
                    _priorityFilter == 1,
                    () => setModalState(() => _priorityFilter = 1),
                  ),
                  _filterChip(
                    "Med",
                    _priorityFilter == 2,
                    () => setModalState(() => _priorityFilter = 2),
                  ),
                  _filterChip(
                    "High",
                    _priorityFilter == 3,
                    () => setModalState(() => _priorityFilter = 3),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Due Date: "),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _dueDateFilter ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setModalState(() => _dueDateFilter = d);
                    },
                    child: Text(
                      _dueDateFilter == null
                          ? "Select Date"
                          : "${_dueDateFilter!.day}/${_dueDateFilter!.month}",
                    ),
                  ),
                  if (_dueDateFilter != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setModalState(() => _dueDateFilter = null),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    setState(() {}); // Rebuild main screen
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Apply Filters",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(color: selected ? AppColors.primary : Colors.black),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final db.Task task;
  final String? assigneeName; // ✅ Added to show member names
  const _TaskCard({required this.task, this.assigneeName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.status == 'done',
            onChanged: (bool? val) {
              ref
                  .read(tasksProvider.notifier)
                  .updateTask(
                    task.copyWith(
                      status: drift.Value(val == true ? 'done' : 'todo'),
                    ),
                  );
            },
            shape: const CircleBorder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: task.status == 'done'
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.status == 'done' ? Colors.grey : Colors.black87,
                  ),
                ),
                if (assigneeName != null)
                  Text(
                    "Assigned to: $assigneeName",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          if (task.priority == 3)
            const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
        ],
      ),
    );
  }
}
