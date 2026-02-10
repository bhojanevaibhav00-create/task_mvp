import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../data/database/database.dart' as db;
import '../../../data/models/enums.dart';

import '../../notifications/presentation/notification_screen.dart';
import 'task_create_edit_screen.dart';
import 'widgets/task_card.dart';

// ✅ IMPORTANT: Correct filter import
import 'package:task_mvp/features/common/widgets/filter_bottom_sheet.dart';
import 'package:task_mvp/features/common//widgets/task_list_empty_state.dart';
import 'package:task_mvp/features/common/widgets/task_list_skeleton.dart';

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

  // ================= CREATE TASK =================
  void _openCreateTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TaskCreateEditScreen()),
    ).then((changed) {
      if (changed == true) {
        ref.read(tasksProvider.notifier).loadTasks();
      }
    });
  }

  void _openEditTask(db.Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskCreateEditScreen(task: task),
      ),
    ).then((changed) {
      if (changed == true) {
        ref.read(tasksProvider.notifier).loadTasks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(filteredTasksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),

          _buildSearchBar(isDark),

          tasksAsync.when(
            loading: () =>
            const SliverFillRemaining(child: TaskListSkeleton()),

            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),

            data: (tasks) {
              final visibleTasks = tasks.where((t) {
                final task = t as db.Task;
                return task.title
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                    (task.description ?? '')
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
              }).toList();

              if (visibleTasks.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child:
                  TaskListEmptyState(onAddTask: _openCreateTask),
                );
              }

              return SliverPadding(
                padding:
                const EdgeInsets.fromLTRB(20, 12, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final db.Task task =
                      visibleTasks[index] as db.Task;

                      return Padding(
                        padding:
                        const EdgeInsets.only(bottom: 12),
                        child: TaskCard(
                          task: task,
                          onTap: () => _openEditTask(task),
                          onToggleDone: () {
                            final isDone = task.status ==
                                TaskStatus.done.name;

                            ref
                                .read(tasksProvider.notifier)
                                .updateTask(
                              task.copyWith(
                                status: drift.Value(
                                  isDone
                                      ? TaskStatus.todo.name
                                      : TaskStatus.done.name,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: visibleTasks.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTask,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ================= APP BAR =================
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding:
        const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          'My Tasks',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration:
          const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      actions: [
        _notificationIcon(),
        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          onPressed: () {
            // ✅ FIXED: correct function call
            openFilterBottomSheet(
              context: context,
              onApply: (
                  statusFilters,
                  priorityFilters,
                  tagFilters,
                  dueBucket,
                  sort,
                  ) {
                // ✅ For now just reload tasks (safe default)
                ref.read(tasksProvider.notifier).loadTasks();
              },
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ================= SEARCH =================
  Widget _buildSearchBar(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Container(
          decoration: BoxDecoration(
            color:
            isDark ? AppColors.inputBackgroundDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) =>
                setState(() => _searchQuery = v),
            decoration: const InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon:
              Icon(Icons.search_rounded, color: Colors.grey),
              border: InputBorder.none,
              contentPadding:
              EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  // ================= NOTIFICATIONS =================
  Widget _notificationIcon() {
    final unread =
    ref.watch(unreadNotificationCountProvider);

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none,
              color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationScreen(),
              ),
            );
          },
        ),
        if (unread > 0)
          Positioned(
            right: 8,
            top: 10,
            child: CircleAvatar(
              radius: 8,
              backgroundColor: Colors.red,
              child: Text(
                unread.toString(),
                style: const TextStyle(
                    fontSize: 10, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}