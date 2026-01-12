import 'package:flutter/material.dart';
import '../data/task_repository.dart';
import '../domain/task_entity.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  Widget build(BuildContext context) {
    final List<TaskEntity> tasks = TaskRepository.getAllTasks();

    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks yet.\nTap + to create one.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final task = tasks[index];

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            title: Text(task.title),
            subtitle: Text(task.status.name.toUpperCase()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(task: task),
                ),
              );
              setState(() {}); // refresh after detail update
            },
          ),
        );
      },
    );
  }
}
