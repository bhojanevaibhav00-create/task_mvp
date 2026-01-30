import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 🚀 Essential for fixing the 'Value' wrapping error
import 'package:drift/drift.dart' as drift; 
import '../../../../data/database/database.dart' as db;
import '../../../../core/providers/task_providers.dart';
import '../../../../core/constants/app_colors.dart';

enum SmartListType { myDay, important, planned, all }

class SmartListScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the live stream of tasks from the database
    final tasksAsync = ref.watch(filteredTasksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddTaskSheet(context, ref),
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          final filteredList = _applySmartFilter(tasks);
          if (filteredList.isEmpty) {
            return const Center(child: Text("No tasks in this list."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filteredList.length,
            itemBuilder: (context, index) => _TaskCard(task: filteredList[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  List<db.Task> _applySmartFilter(List<db.Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (type) {
      case SmartListType.myDay:
        return tasks.where((t) => t.dueDate != null && 
            t.dueDate!.year == today.year && 
            t.dueDate!.month == today.month && 
            t.dueDate!.day == today.day).toList();
      case SmartListType.important:
        return tasks.where((t) => t.priority == 3).toList();
      case SmartListType.planned:
        return tasks.where((t) => t.dueDate != null).toList();
      case SmartListType.all:
      default:
        return tasks;
    }
  }

  void _showAddTaskSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    DateTime? selectedDate = (type == SmartListType.myDay) ? DateTime.now() : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Enter task name...",
                border: InputBorder.none
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.calendar_month, color: AppColors.primary),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) selectedDate = picked;
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: const StadiumBorder()
                  ),
                  onPressed: () {
                    if (controller.text.isEmpty) return;
                    ref.read(tasksProvider.notifier).addTask(
                      controller.text,
                      "",
                      dueDate: selectedDate,
                      priority: (type == SmartListType.important) ? 3 : 1,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Save Task", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final db.Task task;
  const _TaskCard({required this.task});

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
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.status == 'done',
            onChanged: (bool? val) {
              // ✅ FIXED: Using drift.Value to wrap the String.
              // This ensures the database update registers correctly.
              ref.read(tasksProvider.notifier).updateTask(
                task.copyWith(
                  status: drift.Value(val == true ? 'done' : 'todo'),
                ),
              );
            },
            shape: const CircleBorder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                decoration: task.status == 'done' ? TextDecoration.lineThrough : null,
                color: task.status == 'done' ? Colors.grey : Colors.black87,
              ),
            ),
          ),
          if (task.priority == 3) 
            const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
        ],
      ),
    );
  }
}