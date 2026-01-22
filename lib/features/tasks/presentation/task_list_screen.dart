import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/providers/task_providers.dart';
import '../../../data/database/database.dart';
import '../../../data/models/enums.dart';
import '../../../core/constants/app_colors.dart';

import 'task_create_edit_screen.dart';
import 'package:task_mvp/features/tasks/presentation/widgets/task_card.dart';

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
      MaterialPageRoute(builder: (_) => const TaskCreateEditScreen()),
    );

    if (changed == true) {
      ref.read(tasksProvider.notifier).loadTasks();
    }
  }

  Future<void> _openEditTask(Task task) async {
    final changed = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskCreateEditScreen(task: task)),
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
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.red,
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
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
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
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
                  borderRadius: BorderRadius.circular(14),
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
                  return const Center(child: Text('No tasks found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: visibleTasks.length,
                  itemBuilder: (context, index) {
                    final task = visibleTasks[index];
                    final isDone = task.status == TaskStatus.done.name;

                    return TaskCard(
                      task: task,

                      // open edit
                      onTap: () => _openEditTask(task),

                      // toggle status
                      onToggleDone: () async {
                        final newStatus = isDone
                            ? TaskStatus.todo.name
                            : TaskStatus.done.name;

                        await ref.read(tasksProvider.notifier).updateTask(
                              task.copyWith(
                                status: drift.Value(newStatus),
                              ),
                            );
                      },

                      // delete
                      onDelete: () async {
                        await ref
                            .read(tasksProvider.notifier)
                            .deleteTask(task.id);
                      },
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
}
