import 'package:flutter/material.dart';
import '../domain/task_entity.dart';
import 'package:task_mvp/core/constants/app_colors.dart';


class TaskDetailScreen extends StatefulWidget {
  final TaskEntity task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  void _changeStatus() {
    setState(() {
      widget.task.status =
          TaskStatus.values[(widget.task.status.index + 1) % TaskStatus.values.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Chip(
              label: Text(widget.task.status.name.toUpperCase()),
            ),
            const Spacer(),

            ElevatedButton(
              onPressed: _changeStatus,
              child: const Text('Change Status'),
            ),
          ],
        ),
      ),
    );
  }
}
