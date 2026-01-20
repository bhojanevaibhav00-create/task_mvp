import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/enums.dart';

class BoardScreen extends StatefulWidget {
  final Project project;
  const BoardScreen({super.key, required this.project});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  late Map<TaskStatus, List<Task>> groupedTasks;

  @override
  void initState() {
    super.initState();
    _groupTasks();
  }

  void _groupTasks() {
    groupedTasks = {
      for (var status in TaskStatus.values)
        status: widget.project.tasks
            .where((t) => t.status == status)
            .toList(),
    };
  }

  void _updateTaskStatus(Task task, TaskStatus newStatus) {
    setState(() {
      final index = widget.project.tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        widget.project.tasks[index] = widget.project.tasks[index].copyWith(status: newStatus);
        _groupTasks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: TaskStatus.values.map((status) {
            final tasks = groupedTasks[status]!;
            return Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusLabel(status) + " (${tasks.length})",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final task = tasks.removeAt(oldIndex);
                        tasks.insert(newIndex, task);
                        _groupTasks();
                      });
                    },
                    itemBuilder: (_, index) {
                      final task = tasks[index];
                      return Card(
                        key: ValueKey(task.id),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppColors.cardRadius),
                        ),
                        elevation: AppColors.cardElevation,
                        child: ListTile(
                          title: Text(task.title),
                          subtitle: Row(
                            children: [
                              if (task.dueDate != null)
                                Text(
                                  DateFormat('MMM dd').format(task.dueDate!),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (task.important)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.star, size: 14, color: Colors.amber),
                                ),
                            ],
                          ),
                          trailing: DropdownButton<TaskStatus>(
                            value: task.status,
                            items: TaskStatus.values
                                .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(_statusLabel(s)),
                            ))
                                .toList(),
                            onChanged: (newStatus) {
                              if (newStatus != null) {
                                _updateTaskStatus(task, newStatus);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  if (tasks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(AppColors.cardRadius),
                      ),
                      child: Center(
                        child: Text("No tasks"),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return "To Do";
      case TaskStatus.inProgress:
        return "In Progress";
      case TaskStatus.done:
        return "Done";
      case TaskStatus.review:
        return "Review";
    }
  }
}
