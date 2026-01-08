import 'package:flutter/material.dart';
import 'data/database/app_database.dart';
import 'data/repositories/task_repository.dart';
import 'data/seed/seed_data.dart';
import 'domains/enums/task_priority.dart';
import 'domains/enums/task_status.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  await seedDatabase(db);
  runApp(MyApp(db));
}

class MyApp extends StatelessWidget {
  final AppDatabase db;
  const MyApp(this.db, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: TaskDemo(db: db));
  }
}

class TaskDemo extends StatefulWidget {
  final AppDatabase db;
  const TaskDemo({super.key, required this.db});

  @override
  State<TaskDemo> createState() => _TaskDemoState();
}

class _TaskDemoState extends State<TaskDemo> {
  late final TaskRepository repo;
  TaskStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    repo = TaskRepository(widget.db);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Data Demo')),
      body: Column(
        children: [
          // Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _buildFilterChip('All', null),
                ...TaskStatus.values.map((s) => _buildFilterChip(s.name, s)),
              ],
            ),
          ),
          // Task List
          Expanded(
            child: StreamBuilder(
              stream: _filterStatus == null
                  ? repo.watchTasks()
                  : repo.watchByStatus(_filterStatus!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = snapshot.data!;
                if (tasks.isEmpty) {
                  return const Center(child: Text('No tasks found'));
                }
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (_, i) {
                    final task = tasks[i];
                    return Dismissible(
                      key: Key(task.id),
                      background: Container(color: Colors.red),
                      onDismissed: (_) => repo.deleteTask(task.id),
                      child: ListTile(
                        leading: Checkbox(
                          value: task.status == TaskStatus.done,
                          onChanged: (val) {
                            final newStatus = val == true
                                ? TaskStatus.done
                                : TaskStatus.todo;
                            repo.updateStatus(task.id, newStatus);
                          },
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.status == TaskStatus.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          '${task.priority.name.toUpperCase()} • ${task.status.name}',
                        ),
                        trailing: _buildPriorityIcon(task.priority),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, TaskStatus? status) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label.toUpperCase()),
        selected: _filterStatus == status,
        onSelected: (_) => setState(() => _filterStatus = status),
      ),
    );
  }

  Widget _buildPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Icon(Icons.priority_high, color: Colors.red);
      case TaskPriority.medium:
        return const Icon(Icons.remove, color: Colors.orange);
      case TaskPriority.low:
        return const Icon(Icons.arrow_downward, color: Colors.green);
    }
  }

  void _showAddTaskDialog(BuildContext context) {
    String title = '';
    TaskPriority priority = TaskPriority.medium;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Enter task title'),
              onChanged: (value) => title = value,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              value: priority,
              items: TaskPriority.values.map((p) {
                return DropdownMenuItem(value: p, child: Text(p.name));
              }).toList(),
              onChanged: (val) => priority = val!,
              decoration: const InputDecoration(labelText: 'Priority'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (title.trim().isNotEmpty) {
                repo.createTask(
                  title: title,
                  projectId: 'p1',
                  priority: priority,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
