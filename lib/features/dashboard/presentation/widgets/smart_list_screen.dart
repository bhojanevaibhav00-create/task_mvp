import 'package:flutter/material.dart';
import 'package:task_mvp/features/tasks/domain/task.dart';

enum SmartListType { myDay, important, planned, all }

class SmartListScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final SmartListType type;
  final List<Task> tasks;

  const SmartListScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.type,
    required this.tasks,
  });

  @override
  State<SmartListScreen> createState() => _SmartListScreenState();
}

class _SmartListScreenState extends State<SmartListScreen> {
  List<Task> get filteredTasks {
    final now = DateTime.now();
    List<Task> temp = widget.tasks;

    switch (widget.type) {
      case SmartListType.myDay:
        temp = temp.where((t) {
          final d = t.dueDate;
          return d != null &&
              d.day == now.day &&
              d.month == now.month &&
              d.year == now.year;
        }).toList();
        break;
      case SmartListType.important:
        temp = temp.where((t) => t.isImportant).toList();
        break;
      case SmartListType.planned:
        temp = temp.where((t) => t.dueDate != null).toList();
        break;
      case SmartListType.all:
        break;
    }

    return temp;
  }

  void _addTask() {
    final controller = TextEditingController();
    DateTime? dueDate;
    bool isImportant = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Create Task", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Task title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => dueDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(dueDate != null
                      ? "${dueDate!.day}/${dueDate!.month}/${dueDate!.year}"
                      : "Set Due Date"),
                ),
                const SizedBox(width: 12),
                Checkbox(
                  value: isImportant,
                  onChanged: (v) => setState(() => isImportant = v ?? false),
                ),
                const Text("Important"),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.isEmpty) return;
                  setState(() {
                    widget.tasks.add(Task(
                      title: controller.text,
                      dueDate: dueDate,
                      isImportant: isImportant,
                    ));
                  });
                  Navigator.pop(context);
                },
                child: const Text("Add Task"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final dueText = task.dueDate != null
        ? "${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}"
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (v) => setState(() => task.isCompleted = v ?? false),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            if (task.isImportant)
              const Icon(Icons.star, color: Colors.amber, size: 16),
            if (dueText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(dueText, style: const TextStyle(fontSize: 12, color: Colors.blue)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(widget.icon),
            const SizedBox(width: 8),
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(onPressed: _addTask, icon: const Icon(Icons.add)),
        ],
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: filteredTasks.isEmpty
          ? const Center(child: Text("No tasks yet"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTasks.length,
        itemBuilder: (_, index) => _buildTaskCard(filteredTasks[index]),
      ),
    );
  }
}
