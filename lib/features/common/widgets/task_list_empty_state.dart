import 'package:flutter/material.dart';

class TaskListEmptyState extends StatelessWidget {
  final VoidCallback onAddTask;
  const TaskListEmptyState({super.key, required this.onAddTask});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'No tasks yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onAddTask,
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }
}