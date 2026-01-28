import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../data/database/database.dart';
import '../../../data/models/enums.dart';

import '../../notifications/presentation/notification_screen.dart';
import 'task_create_edit_screen.dart';
import 'widgets/task_card.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/filter_bottom_sheet.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/task_list_empty_state.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/task_list_skeleton.dart';


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

  // ================= CREATE TASK (UPDATED) =================
  Future<void> _openCreateTask() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, __) {
            return Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const TaskCreateEditScreen(),
            );
          },
        );
      },
    );

    if (changed == true) {
      ref.read(tasksProvider.notifier).loadTasks();
    }
  }

  // ================= EDIT TASK (UNCHANGED) =================
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,

      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text('Tasks'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          // Notifications
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
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

          // Filter
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              openFilterBottomSheet(
                context: context,
                allTags: const [],
                statusFilters: {},
                priorityFilters: {},
                tagFilters: {},
                dueBucket: null,
                sort: null,
                onApply: (_, __, ___, ____, _____) {},
              );
            },
          ),
        ],
      ),

      // ================= BODY =================
      body: Column(
        children: [
          // ================= SEARCH BAR =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search tasks',
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
                fillColor: isDark
                    ? AppColors.inputBackgroundDark
                    : AppColors.inputBackgroundLight,
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
              const TaskListSkeleton(),
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
                  return TaskListEmptyState(
                    onAddTask: _openCreateTask,
                  );
                }


                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: visibleTasks.length,
                  itemBuilder: (context, index) {
                    final task = visibleTasks[index];
                    final isDone =
                        task.status == TaskStatus.done.name;

                    return TaskCard(
                      task: task,

                      onTap: () => _openEditTask(task),

                      onToggleDone: () async {
                        final newStatus = isDone
                            ? TaskStatus.todo.name
                            : TaskStatus.done.name;

                        await ref
                            .read(tasksProvider.notifier)
                            .updateTask(
                          task.copyWith(
                            status: drift.Value(newStatus),
                          ),
                        );
                      },

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

      // ================= FAB =================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.fabBackground,
        foregroundColor: AppColors.fabForeground,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        onPressed: _openCreateTask,
      ),
    );
  }
}
