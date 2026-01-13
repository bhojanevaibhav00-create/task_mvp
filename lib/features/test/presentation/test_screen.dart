import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:task_mvp/data/database/database.dart';
import 'package:task_mvp/data/repositories/task_repository.dart';
import 'package:task_mvp/core/constants/app_routes.dart';
import 'package:task_mvp/core/widgets/app_button.dart';
import 'package:task_mvp/core/utils/logger.dart';
import 'package:drift/drift.dart' as drift;
import 'package:task_mvp/data/models/enums.dart';
import 'package:task_mvp/data/models/task_extensions.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late final AppDatabase _db;
  late final TaskRepository _taskRepo;
  String _status = 'Ready';

  @override
  void initState() {
    super.initState();
    _db = AppDatabase();
    _taskRepo = TaskRepository(_db);
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  Future<void> _addTask() async {
    try {
      final companion = TasksCompanion(
        title: drift.Value(
          'Test Task ${DateTime.now().millisecondsSinceEpoch}',
        ),
        description: const drift.Value('This is a test task'),
        status: const drift.Value('todo'),
        priority: const drift.Value(1),
        dueDate: drift.Value(DateTime.now().add(const Duration(days: 1))),
      );
      await _taskRepo.createTask(companion);
      setState(() {
        _status = 'Task added';
      });
    } catch (e) {
      setState(() {
        _status = 'Error adding task: $e';
      });
    }
  }

  Future<void> _advanceTaskStatus(Task task) async {
    try {
      final currentStatusString = task.status;
      TaskStatus currentStatus = TaskStatus.todo;

      if (currentStatusString != null) {
        currentStatus = TaskStatus.values.firstWhere(
          (e) => e.name == currentStatusString,
          orElse: () => TaskStatus.todo,
        );
      }

      final nextStatus = currentStatus.next;
      final updatedTask = task.copyWith(status: drift.Value(nextStatus.name));

      await _taskRepo.updateTask(updatedTask);
      setState(() {
        _status = 'Task updated: ${currentStatus.label} -> ${nextStatus.label}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error updating task status: $e';
      });
    }
  }

  Future<void> _deleteAllTasks() async {
    try {
      await _taskRepo.deleteAllTasks();
      setState(() {
        _status = 'All tasks deleted';
      });
    } catch (e) {
      setState(() {
        _status = 'Error deleting tasks: $e';
      });
    }
  }

  void _testLogger() {
    debugPrint('Test log message from TestScreen');
    setState(() {
      _status = 'Logger tested - check console';
    });
  }

  void _navigateTo(String route) {
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backend Test UI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Text('Status: $_status', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            // Database Tests
            const Text(
              'Database Tests:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Add Test Task'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Refresh Tasks'),
                ),
                ElevatedButton(
                  onPressed: _deleteAllTasks,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete All'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 20),

            // Navigation Tests
            const Text(
              'Navigation Tests:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () => _navigateTo(AppRoutes.login),
                  child: const Text('Go to Login'),
                ),
                ElevatedButton(
                  onPressed: () => _navigateTo(AppRoutes.dashboard),
                  child: const Text('Go to Dashboard'),
                ),
                ElevatedButton(
                  onPressed: () => _navigateTo(AppRoutes.tasks),
                  child: const Text('Go to Tasks'),
                ),
                ElevatedButton(
                  onPressed: () => _navigateTo(AppRoutes.demo),
                  child: const Text('Go to Demo'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Core Utils Tests
            const Text(
              'Core Utils Tests:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testLogger,
              child: const Text('Test Logger'),
            ),
            const SizedBox(height: 20),

            // Core Widgets Tests
            const Text(
              'Core Widgets Tests:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            AppButton(
              text: 'Test AppButton',
              onPressed: () {
                setState(() {
                  _status = 'AppButton pressed';
                });
              },
            ),
            const SizedBox(height: 20),

            // Theme Tests
            const Text(
              'Theme Tests:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor,
              child: Text(
                'Primary Color: ${Theme.of(context).primaryColor}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Background Color: ${Theme.of(context).scaffoldBackgroundColor}',
            ),
            const SizedBox(height: 20),

            // Tasks List
            const Text(
              'Tasks:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<Task>>(
                stream: _taskRepo.watchAllTasks(),
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
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.status == TaskStatus.done.name
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.status == TaskStatus.done.name
                                ? Colors.grey
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          'ID: ${task.id}, Status: ${task.status}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
