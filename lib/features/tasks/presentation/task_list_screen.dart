import 'dart:ui';
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
import 'package:task_mvp/features/dashboard/presentation/widgets/filter_bottom_sheet.dart';
import 'package:task_mvp/features/common/widgets/task_list_empty_state.dart';
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
      MaterialPageRoute(builder: (_) => TaskCreateEditScreen(task: task)),
    ).then((changed) {
      if (changed == true) {
        ref.read(tasksProvider.notifier).loadTasks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasksAsync = ref.watch(filteredTasksProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : const Color(0xFFF6F7FB),

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ================= APP BAR =================
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: AppColors.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
              const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'My Tasks',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),
            ),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 10,
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
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.filter_list,
                    color: Colors.white),
                onPressed: () => openFilterBottomSheet(
                  context: context,
                  allTags: const [],
                  statusFilters: {},
                  priorityFilters: {},
                  tagFilters: {},
                  dueBucket: null,
                  sort: null,
                  onApply: (_, __, ___, ____, _____) {},
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ================= SEARCH =================
          SliverToBoxAdapter(
            child: Padding(
              padding:
              const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark
                      ? []
                      : [
                    BoxShadow(
                      color:
                      Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      setState(() => _searchQuery = v),
                  style: TextStyle(
                    color:
                    isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search your tasks...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.white38
                          : const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark
                          ? Colors.white38
                          : const Color(0xFF6B7280),
                    ),
                    border: InputBorder.none,
                    contentPadding:
                    const EdgeInsets.symmetric(
                        vertical: 16),
                  ),
                ),
              ),
            ),
          ),

          // ================= TASK LIST =================
          filteredTasksAsync.when(
            loading: () => const SliverFillRemaining(
              child: TaskListSkeleton(),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Error: $e',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : Colors.black87,
                  ),
                ),
              ),
            ),
            data: (tasksData) {
              final List tasks =
              tasksData is List ? tasksData : [];

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
                  child: TaskListEmptyState(
                      onAddTask: _openCreateTask),
                );
              }

              return SliverPadding(
                padding:
                const EdgeInsets.fromLTRB(20, 8, 20, 100),
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
                          onTap: () =>
                              _openEditTask(task),
                          onToggleDone: () {
                            final isDone =
                                task.status ==
                                    TaskStatus.done.name;
                            final newStatus = isDone
                                ? TaskStatus.todo.name
                                : TaskStatus.done.name;

                            ref
                                .read(tasksProvider.notifier)
                                .updateTask(
                              task.copyWith(
                                status: drift.Value(
                                    newStatus),
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

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: _openCreateTask,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded,
            color: Colors.white),
        label: const Text(
          'Add Task',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}