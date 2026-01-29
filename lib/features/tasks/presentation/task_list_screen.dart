import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../data/database/database.dart' as db;
import '../../../core/providers/task_providers.dart';
import '../../../data/models/enums.dart';
import '../../../core/constants/app_colors.dart';

import '../../projects/presentation/project_members_screen.dart';
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

  void _navigateToMembers() {
    final currentProjectId = ref.read(projectFilterProvider) ?? 1;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectMembersScreen(projectId: currentProjectId),
      ),
    );
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          _buildCollaborationTools(),
          filteredTasksAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (dynamic tasksData) {
              final List tasks = tasksData is List ? tasksData : [];
              
              // Apply search filter
              final visibleTasks = tasks.where((t) {
                final task = t as db.Task;
                return task.title.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

              // 🚀 FIX: Correctly show "No tasks found" when the list is empty
              if (visibleTasks.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final db.Task task = visibleTasks[index] as db.Task;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TaskCard(
                          task: task,
                          onTap: () => _openEditTask(task), // Task is clickable again
                          onToggleDone: () {
                            final isDone = task.status == TaskStatus.done.name;
                            final newStatus = isDone ? TaskStatus.todo.name : TaskStatus.done.name;
                            ref.read(tasksProvider.notifier).updateTask(
                                  task.copyWith(status: drift.Value(newStatus)),
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
        label: const Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text('My Tasks', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        background: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
      ),
      actions: [
        // 🚀 FIX: Removed the extra "People" icon here to avoid two options
        _buildNotificationIcon(ref),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCollaborationTools() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTeamShortcutChip(),
            const SizedBox(height: 16),
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamShortcutChip() {
    return GestureDetector(
      onTap: _navigateToMembers,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_add_rounded, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text("Manage Project Team", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: const InputDecoration(
          hintText: 'Search your tasks...',
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
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
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationScreen())),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No tasks found' : 'No results for "$_searchQuery"',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}