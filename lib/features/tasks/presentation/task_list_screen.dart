import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/providers/task_providers.dart';
import '../../../data/database/database.dart';
import '../../../data/models/enums.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int _priority = 1;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    _titleController.clear();
    _descriptionController.clear();
    _priority = 1;
    _selectedDate = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              DropdownButtonFormField<int>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Low')),
                  DropdownMenuItem(value: 2, child: Text('Medium')),
                  DropdownMenuItem(value: 3, child: Text('High')),
                ],
                onChanged: (value) {
                  setState(() => _priority = value ?? 1);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Due Date: '),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    child: Text(_formatDate(_selectedDate) ?? 'Select Date'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isNotEmpty) {
                  await ref
                      .read(tasksProvider.notifier)
                      .addTask(
                        _titleController.text,
                        _descriptionController.text,
                        priority: _priority,
                        dueDate: _selectedDate,
                      );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    _titleController.text = task.title;
    _descriptionController.text = task.description ?? '';
    _priority = task.priority ?? 1;
    _selectedDate = task.dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              DropdownButtonFormField<int>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Low')),
                  DropdownMenuItem(value: 2, child: Text('Medium')),
                  DropdownMenuItem(value: 3, child: Text('High')),
                ],
                onChanged: (value) {
                  setState(() => _priority = value ?? 1);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Due Date: '),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    child: Text(_formatDate(_selectedDate) ?? 'Select Date'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedTask = task.copyWith(
                  title: _titleController.text,
                  description: drift.Value(
                    _descriptionController.text.isEmpty
                        ? null
                        : _descriptionController.text,
                  ),
                  priority: drift.Value(_priority),
                  dueDate: drift.Value(_selectedDate),
                );
                await ref.read(tasksProvider.notifier).updateTask(updatedTask);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasksAsync = ref.watch(filteredTasksProvider);
    final statusFilter = ref.watch(statusFilterProvider);
    final sortBy = ref.watch(sortByProvider);
    final overdueFilter = ref.watch(overdueFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Seed Demo Data',
            onPressed: () => ref.read(tasksProvider.notifier).seedData(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddTaskDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters and Sort
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Overdue'),
                        selected: overdueFilter,
                        onSelected: (selected) {
                          ref.read(overdueFilterProvider.notifier).state =
                              selected;
                        },
                        selectedColor: Colors.red.shade100,
                        checkmarkColor: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      if (!overdueFilter) ...[
                        const Text('Status: '),
                        DropdownButton<String>(
                          value: statusFilter,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All')),
                            DropdownMenuItem(
                              value: 'todo',
                              child: Text('To Do'),
                            ),
                            DropdownMenuItem(
                              value: 'done',
                              child: Text('Done'),
                            ),
                          ],
                          onChanged: (value) {
                            ref.read(statusFilterProvider.notifier).state =
                                value ?? 'all';
                          },
                        ),
                        const SizedBox(width: 16),
                      ],
                      const Text('Sort: '),
                      DropdownButton<String>(
                        value: sortBy,
                        items: const [
                          DropdownMenuItem(value: 'date', child: Text('Date')),
                          DropdownMenuItem(
                            value: 'title',
                            child: Text('Title'),
                          ),
                          DropdownMenuItem(
                            value: 'priority',
                            child: Text('Priority'),
                          ),
                        ],
                        onChanged: (value) {
                          ref.read(sortByProvider.notifier).state =
                              value ?? 'date';
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Task List
          Expanded(
            child: filteredTasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (tasks) {
                if (tasks.isEmpty)
                  return const Center(child: Text('No tasks found'));
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isOverdue =
                        task.dueDate != null &&
                        task.dueDate!.isBefore(DateTime.now()) &&
                        task.status != TaskStatus.done.name;
                    final priorityColor = _getPriorityColor(task.priority ?? 1);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(task.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task.description?.isNotEmpty ?? false)
                              Text(task.description!),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: priorityColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: priorityColor),
                                  ),
                                  child: Text(
                                    _getPriorityText(task.priority ?? 1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: priorityColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (task.dueDate != null)
                                  Text(
                                    'Due: ${_formatDate(task.dueDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isOverdue
                                          ? Colors.red
                                          : Colors.grey,
                                      fontWeight: isOverdue
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                              ],
                            ),
                            if (isOverdue)
                              const Text(
                                'OVERDUE',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                task.status == TaskStatus.done.name
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: task.status == TaskStatus.done.name
                                    ? Colors.green
                                    : null,
                              ),
                              onPressed: () async {
                                final newStatus =
                                    task.status == TaskStatus.done.name
                                    ? TaskStatus.todo.name
                                    : TaskStatus.done.name;
                                final updatedTask = task.copyWith(
                                  status: drift.Value(newStatus),
                                );
                                await ref
                                    .read(tasksProvider.notifier)
                                    .updateTask(updatedTask);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditTaskDialog(task),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await ref
                                    .read(tasksProvider.notifier)
                                    .deleteTask(task.id);
                              },
                            ),
                          ],
                        ),
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
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Unknown';
    }
  }
}
