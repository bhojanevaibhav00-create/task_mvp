import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/providers/task_providers.dart';
import '../../../data/database/database.dart';
import '../../../data/models/enums.dart';

import 'task_create_edit_screen.dart';

import 'package:task_mvp/core/providers/notification_providers.dart';
import 'package:task_mvp/features/notifications/presentation/notification_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= NAVIGATION =================
  Future<void> _openCreateTask() async {
    final changed = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TaskCreateEditScreen(),
      ),
    );

    if (changed == true) {
      ref.read(tasksProvider.notifier).loadTasks();
    }
  }

  Future<void> _openEditTask(Task task) async {
    final changed = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskCreateEditScreen(task: task),
      ),
    );

    if (changed == true) {
      ref.read(tasksProvider.notifier).loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasksAsync = ref.watch(filteredTasksProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ================= SEARCH =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ================= TASK LIST =================
          Expanded(
            child: filteredTasksAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (tasks) {
                final visibleTasks = tasks.where((task) {
                  if (_searchQuery.isEmpty) return true;
                  return task.title.toLowerCase().contains(_searchQuery) ||
                      (task.description ?? '')
                          .toLowerCase()
                          .contains(_searchQuery);
                }).toList();

                if (visibleTasks.isEmpty) {
                  return const Center(
                      child: Text('No matching tasks found'));
                }

                return ListView.builder(
                  itemCount: visibleTasks.length,
                  itemBuilder: (context, index) {
                    final task = visibleTasks[index];

                    final isOverdue = task.dueDate != null &&
                        task.dueDate!.isBefore(DateTime.now()) &&
                        task.status != TaskStatus.done.name;

                    final priorityColor =
                        _getPriorityColor(task.priority ?? 1);

                    return InkWell(
                      onTap: () => _openEditTask(task),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    if (task.description?.isNotEmpty ??
                                        false)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4),
                                        child: Text(
                                          task.description!,
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: priorityColor
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: priorityColor),
                                          ),
                                          child: Text(
                                            _getPriorityText(
                                                task.priority ?? 1),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.bold,
                                              color: priorityColor,
                                            ),
                                          ),
                                        ),
                                        if (task.dueDate != null)
                                          Text(
                                            'Due: ${_formatDate(task.dueDate)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isOverdue
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (isOverdue)
                                      const Padding(
                                        padding:
                                            EdgeInsets.only(top: 4),
                                        child: Text(
                                          'OVERDUE',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      task.status ==
                                              TaskStatus.done.name
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: task.status ==
                                              TaskStatus.done.name
                                          ? Colors.green
                                          : null,
                                    ),
                                    onPressed: () async {
                                      final newStatus =
                                          task.status ==
                                                  TaskStatus.done.name
                                              ? TaskStatus.todo.name
                                              : TaskStatus.done.name;

                                      await ref
                                          .read(tasksProvider.notifier)
                                          .updateTask(
                                            task.copyWith(
                                              status:
                                                  drift.Value(newStatus),
                                            ),
                                          );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () async {
                                      await ref
                                          .read(tasksProvider.notifier)
                                          .deleteTask(task.id);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
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
        onPressed: _openCreateTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ================= HELPERS =================
  String _formatDate(DateTime? date) =>
      date == null ? '' : '${date.day}/${date.month}/${date.year}';

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
