import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

// Aliasing the database to 'db' to ensure the 'Task' type is unique and correct
import '../../../data/database/database.dart' as db;
import '../../../core/providers/task_providers.dart';
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

  // ================= NAVIGATION FIXES =================

  // Using a static BuildContext-free navigation approach to avoid context bugs
  void _openCreateTask() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TaskCreateEditScreen(),
      ),
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
        builder: (context) => TaskCreateEditScreen(task: task),
      ),
    ).then((changed) {
      if (changed == true) {
        ref.read(tasksProvider.notifier).loadTasks();
      }
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
          // ================= APP BAR =================
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'My Tasks',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              ),
            ),
            actions: [
              _buildNotificationIcon(ref),
              const SizedBox(width: 8),
            ],
          ),

          // ================= SEARCH BAR =================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: _buildSearchBar(),
            ),
          ),

          // ================= TASK LIST =================
          filteredTasksAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (dynamic tasksData) {
              final List tasks = tasksData is List ? tasksData : [];

              final visibleTasks = tasks.where((t) {
                final task = t as db.Task;
                if (_searchQuery.isEmpty) return true;
                return task.title.toLowerCase().contains(_searchQuery) ||
                    (task.description ?? '').toLowerCase().contains(_searchQuery);
              }).toList();

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
                      final isDone = task.status == TaskStatus.done.name;

                      return Dismissible(
                        key: ValueKey('task_${task.id}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          ref.read(tasksProvider.notifier).deleteTask(task.id);
                        },
                        background: _buildDeleteBackground(),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TaskCard(
                            task: task,
                            onTap: () => _openEditTask(task),
                            onToggleDone: () {
                              final newStatus = isDone ? TaskStatus.todo.name : TaskStatus.done.name;
                              ref.read(tasksProvider.notifier).updateTask(
                                    task.copyWith(status: drift.Value(newStatus)),
                                  );
                            },
                          ),
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
      // FLOATING ACTION BUTTON FIX
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTask, // Direct function reference
        label: const Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        backgroundColor: AppColors.primary,
        elevation: 6,
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildSearchBar() {
    const darkText = Color(0xFF111827);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: darkText, fontSize: 16),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search your tasks...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          // Explicitly setting icon colors to avoid "invisible icon" bug
          prefixIcon: const Icon(
            Icons.search_rounded, 
            color: Color(0xFF6B7280), // Medium Gray for visibility
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.cancel_rounded, color: Color(0xFF6B7280)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 25),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.shade400,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 30),
    );
  }

  Widget _buildNotificationIcon(WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
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