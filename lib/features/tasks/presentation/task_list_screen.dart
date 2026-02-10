import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../data/database/database.dart' as db;
import '../../../data/models/enums.dart';
import '../../../data/repositories/task_repository.dart'; // ✅ Required for TaskWithAssignee

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
  Set<String> _dueBucketFilter = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateTask() {
    context
        .push('/tasks/new')
        .then((_) => ref.read(tasksProvider.notifier).loadTasks());
  }

  void _openEditTask(db.Task task) {
    context
        .push('/tasks/${task.id}')
        .then((_) => ref.read(tasksProvider.notifier).loadTasks());
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 Watching the provider which now returns TaskWithAssignee wrappers
    final filteredTasksAsync = ref.watch(filteredTasksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          _buildSearchHeader(),
          filteredTasksAsync.when(
            loading: () => const SliverFillRemaining(child: TaskListSkeleton()),
            error: (e, _) =>
                SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (List<TaskWithAssignee> wrappers) {
              // ✅ Step 1: Filter and unwrap the wrappers
              Iterable<TaskWithAssignee> filteredWrappers = wrappers;

              // Filter by bucket if local filter is active
              if (_dueBucketFilter.isNotEmpty) {
                final bucket = _dueBucketFilter.first.toLowerCase();
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                filteredWrappers = filteredWrappers.where((w) {
                  final t = w.task;
                  if (bucket == 'no_date') return t.dueDate == null;
                  if (t.dueDate == null) return false;

                  final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
                  switch (bucket) {
                    case 'overdue':
                      return d.isBefore(today) && t.status != 'done';
                    case 'today':
                      return d.isAtSameMomentAs(today);
                    case 'tomorrow':
                      return d.isAtSameMomentAs(today.add(const Duration(days: 1)));
                    case 'this_week':
                      final nextWeek = today.add(const Duration(days: 7));
                      return !d.isBefore(today) && d.isBefore(nextWeek);
                    default:
                      return true;
                  }
                });
              }

              // Filter by search query
              final visibleWrappers = filteredWrappers.where((w) {
                final task = w.task;
                final query = _searchQuery.toLowerCase();
                return task.title.toLowerCase().contains(query) ||
                    (task.description ?? '').toLowerCase().contains(query);
              }).toList();

              if (visibleWrappers.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildPremiumEmptyState(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = visibleWrappers[index];
                    final task = item.task;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskCard(
                        task: task,
                        // ✅ FIXED: Pass the member name from the joined result
                        assigneeName: item.assignee?.name,
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
                  }, childCount: visibleWrappers.length),
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: AppColors.primary,
      elevation: 0,
      leadingWidth: 72, 
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        padding: const EdgeInsets.only(left: 12),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 72, bottom: 16), 
        title: const Text(
          'My Tasks',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
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
          icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
          onPressed: () => _showFilters(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Color(0xFF111827), fontSize: 15, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: 'Search your tasks...',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.normal),
              prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 15),
              filled: true,
              fillColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_add,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No tasks found",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Your schedule is clear. Add a new task to get started.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _openCreateTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Create Task", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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
          onPressed: () => context.push('/notifications'),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 10,
            child: CircleAvatar(
              radius: 8,
              backgroundColor: Colors.red,
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

  void _showFilters() {
    final currentStatus = ref.read(statusFilterProvider);
    final currentPriority = ref.read(priorityFilterProvider);

    openFilterBottomSheet(
      context: context,
      allTags: const [],
      statusFilters: currentStatus == 'all' ? {} : {currentStatus},
      priorityFilters: currentPriority == null ? {} : {currentPriority},
      tagFilters: {},
      dueBucket: _dueBucketFilter.isNotEmpty ? _dueBucketFilter.first : null,
      sort: null,
      onApply: (statuses, priorities, tags, dueBucket, sort) {
        if (statuses.isEmpty) {
          ref.read(statusFilterProvider.notifier).state = 'all';
        } else {
          final dbStatus = TaskStatus.fromUItoDB(statuses.first);
          ref.read(statusFilterProvider.notifier).state = dbStatus;
        }

        if (priorities.isEmpty) {
          ref.read(priorityFilterProvider.notifier).state = null;
        } else {
          ref.read(priorityFilterProvider.notifier).state = priorities.first;
        }

        if (sort != null) {
          final s = sort.toString().toLowerCase();
          if (s.contains('priority')) {
            ref.read(sortByProvider.notifier).state = 'priority_desc';
          } else if (s.contains('date') || s.contains('due')) {
            ref.read(sortByProvider.notifier).state = 'due_date_asc';
          } else {
            ref.read(sortByProvider.notifier).state = 'updated_at_desc';
          }
        }

        setState(() {
          final bucket = dueBucket as String?;
          _dueBucketFilter = bucket != null ? {bucket} : {};
          
          if (bucket != null) {
            ref.read(dueBucketFilterProvider.notifier).state = bucket;
          } else {
            ref.read(dueBucketFilterProvider.notifier).state = null;
          }
        });
      },
    );
  }
}