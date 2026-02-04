import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:task_mvp/core/constants/app_colors.dart';
import 'package:task_mvp/core/providers/task_providers.dart';
import 'package:task_mvp/data/models/enums.dart';

import 'package:task_mvp/features/dashboard/presentation/widgets/active_filter_chips.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/filter_bottom_sheet.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  /// 🔹 FILTER STATES (SINGLE SOURCE OF TRUTH)
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
                tagFilters: const {},
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
          /// ✅ ACTIVE FILTER CHIPS (FIXED)
          ActiveFilterChips(
            statuses: statusFilters,
            priorities: priorityFilters,
            due: dueBucket,
            onClear: () {
              setState(() {
                statusFilters.clear();
                priorityFilters.clear();
                dueBucket = null;
              });
            },
          ),

          /// 🔹 TASK LIST
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('No tasks found'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (_, index) {
                final task = tasks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color:
                    isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing:
                    const Icon(Icons.chevron_right),
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
