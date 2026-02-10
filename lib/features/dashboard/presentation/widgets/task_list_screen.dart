import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/task_providers.dart';
import '../../../../data/database/database.dart';
import '../../../../data/models/enums.dart';

import '../widgets/active_filter_chips.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/task_tile.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/task_tile.dart';
import 'package:task_mvp/features/tasks/presentation/task_detail_screen.dart';
import 'package:task_mvp/core/providers/task_providers.dart';
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  /// ✅ FILTER STATE (NOW VALID TYPES)
  final Set<TaskStatus> statusFilters = {};
  final Set<Priority> priorityFilters = {};
  String? dueBucket;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              openFilterBottomSheet(
                context: context,
                allTags: const [],
                statusFilters: statusFilters,
                priorityFilters: priorityFilters,
                tagFilters: {},
                dueBucket: dueBucket,
                sort: null,
                onApply: (s, p, _, d, __) {
                  setState(() {
                    statusFilters
                      ..clear()
                      ..addAll(s);
                    priorityFilters
                      ..clear()
                      ..addAll(p);
                    dueBucket = d;
                  });
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          /// ✅ ACTIVE FILTER CHIPS
          ActiveFilterChips(
            statuses: statusFilters,
            priorities: priorityFilters,
            due: dueBucket,
            onClearAll: () {
              setState(() {
                statusFilters.clear();
                priorityFilters.clear();
                dueBucket = null;
              });
            },
          ),

          /// ✅ TASK LIST
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('No tasks found'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (_, index) {
                final task = tasks[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskTile(
                    task: task,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(task: task),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}