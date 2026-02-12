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
      MaterialPageRoute(builder: (context) => const TaskCreateEditScreen()),
    ).then((changed) {
      if (changed == true) ref.read(tasksProvider.notifier).loadTasks();
    });
  }

  void _openEditTask(db.Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskCreateEditScreen(task: task)),
    ).then((changed) {
      if (changed == true) ref.read(tasksProvider.notifier).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasksAsync = ref.watch(filteredTasksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Dynamic background color to prevent white flashes
      backgroundColor: isDark
          ? AppColors.scaffoldDark
          : const Color(0xFFF8F9FD),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(isDark),
          _buildSearchHeader(isDark),
          filteredTasksAsync.when(
            loading: () => const SliverFillRemaining(child: TaskListSkeleton()),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Error: $e',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),
            data: (dynamic tasksData) {
              final List tasks = tasksData is List ? tasksData : [];

              final visibleTasks = tasks.where((t) {
                final db.Task task = t is db.Task ? t : (t as dynamic).task;
                return task.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (task.description ?? '').toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );
              }).toList();

              if (visibleTasks.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: TaskListEmptyState(onAddTask: _openCreateTask),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = visibleTasks[index];
                    final db.Task task = item is db.Task
                        ? item
                        : (item as dynamic).task;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskCard(
                        task: task,
                        onTap: () => _openEditTask(task),
                        onToggleDone: () {
                          final isDone = task.status == TaskStatus.done.name;
                          final newStatus = isDone
                              ? TaskStatus.todo.name
                              : TaskStatus.done.name;
                          ref
                              .read(tasksProvider.notifier)
                              .updateTask(
                                task.copyWith(status: drift.Value(newStatus)),
                              );
                        },
                      ),
                    );
                  }, childCount: visibleTasks.length),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTask,
        label: const Text(
          'Add Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        backgroundColor: AppColors.primary,
        elevation: 6,
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          'My Tasks',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      actions: [
        _buildNotificationIcon(ref),
        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          onPressed: () {
            final status = ref.read(statusFilterProvider);
            final priority = ref.read(priorityFilterProvider);
            final dueBucket = ref.read(dueBucketFilterProvider);
            final sort = ref.read(sortByProvider);

            // Safe mapping for Status
            final Set<TaskStatus> initialStatus = status != 'all'
                ? TaskStatus.values.where((e) => e.name == status).toSet()
                : {};

            // Safe mapping for Priority (DB 1-based -> Enum 0-based)
            final Set<Priority> initialPriority =
                (priority != null &&
                    priority > 0 &&
                    priority <= Priority.values.length)
                ? {Priority.values[priority - 1]}
                : {};

            openFilterBottomSheet(
              context: context,
              allTags: const [],
              statusFilters: initialStatus,
              priorityFilters: initialPriority,
              tagFilters: {},
              dueBucket: dueBucket,
              sort: sort,
              onApply: (statuses, priorities, tags, bucket, newSort) {
                ref
                    .read(statusFilterProvider.notifier)
                    .state = statuses.isNotEmpty
                    ? (statuses.first as TaskStatus).name
                    : 'all';
                ref
                    .read(priorityFilterProvider.notifier)
                    .state = priorities.isNotEmpty
                    ? (priorities.first as Priority).index + 1
                    : null;
                ref.read(dueBucketFilterProvider.notifier).state = bucket;
                if (newSort != null) {
                  ref.read(sortByProvider.notifier).state = newSort;
                }
              },
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchHeader(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        child: Container(
          decoration: BoxDecoration(
            // Changed hardcoded Colors.white to cardDark
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Search your tasks...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark ? Colors.white38 : const Color(0xFF6B7280),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              filled: true,
              fillColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const NotificationScreen())),
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
    );
  }
}
