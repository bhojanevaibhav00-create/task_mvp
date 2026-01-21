// ignore_for_file: unused_element, unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

import 'package:task_mvp/data/database/database.dart';
import 'package:task_mvp/core/constants/app_routes.dart';
import 'package:task_mvp/core/widgets/app_button.dart';
import 'package:task_mvp/core/providers/task_providers.dart';
import 'package:task_mvp/data/models/enums.dart';
import 'package:task_mvp/data/models/task_extensions.dart';

class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({super.key});

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  String _status = 'Ready';

  // ================= ADD TASK =================
  Future<void> _addTask() async {
    try {
      final companion = TasksCompanion.insert(
        title: 'Test Task ${DateTime.now().millisecondsSinceEpoch}',
        description: const drift.Value('This is a test task'),
        status: drift.Value(TaskStatus.todo.name),
        priority: const drift.Value(1),
        dueDate: drift.Value(DateTime.now().add(const Duration(days: 1))),
      );

      await ref.read(taskRepositoryProvider).createTask(companion);

      setState(() => _status = 'Task added successfully');
    } catch (e) {
      setState(() => _status = 'Error adding task: $e');
    }
  }

  // ================= ADVANCE STATUS =================
  Future<void> _advanceTaskStatus(Task task) async {
    try {
      final currentStatus = TaskStatus.values.firstWhere(
        (e) => e.name == task.status,
        orElse: () => TaskStatus.todo,
      );

      final nextStatus = currentStatus.next;

      final updatedTask = task.copyWith(
        status: drift.Value(nextStatus.name),
      );

      await ref.read(taskRepositoryProvider).updateTask(updatedTask);

      setState(() {
        _status = 'Status: ${currentStatus.label} → ${nextStatus.label}';
      });
    } catch (e) {
      setState(() => _status = 'Error updating task: $e');
    }
  }

  // ================= DELETE ALL =================
  Future<void> _deleteAllTasks() async {
    try {
      await ref.read(taskRepositoryProvider).deleteAllTasks();
      setState(() => _status = 'All tasks deleted');
    } catch (e) {
      setState(() => _status = 'Error deleting tasks: $e');
    }
  }

  // ================= DB VERSION =================
  Future<void> _checkDbVersion() async {
    try {
      final version =
          await ref.read(taskRepositoryProvider).getDatabaseVersion();
      setState(() => _status = 'Database Version: $version');
    } catch (e) {
      setState(() => _status = 'DB version error: $e');
    }
  }

  void _navigateTo(String route) => context.go(route);

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final taskRepo = ref.watch(taskRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Backend Test UI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $_status', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            const Text(
              'Database Tests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Add Task'),
                ),
                ElevatedButton(
                  onPressed: _deleteAllTasks,
                  child: const Text('Delete All'),
                ),
                ElevatedButton(
                  onPressed: _checkDbVersion,
                  child: const Text('Check DB Version'),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              'Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 250,
              child: StreamBuilder<List<Task>>(
                stream: taskRepo.watchTasks(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = snapshot.data!;
                  if (tasks.isEmpty) {
                    return const Text('No tasks found');
                  }

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return ListTile(
                        leading: Checkbox(
                          value: task.status == TaskStatus.done.name,
                          onChanged: (_) => _advanceTaskStatus(task),
                        ),
                        title: Text(task.title),
                        subtitle: Text('ID: ${task.id}'),
                        onTap: () => _advanceTaskStatus(task),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
