import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/tag_model.dart';
import '../../../../data/models/enums.dart';

import 'widgets/project_card_improved.dart';
import 'widgets/project_skeleton.dart';
import 'widgets/empty_state.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/task_bottom_sheet.dart';

import 'package:task_mvp/features/dashboard/presentation/board_screen.dart';
import 'package:task_mvp/features/dashboard/presentation/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const DashboardScreen({super.key, required this.onToggleTheme});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String searchQuery = "";
  bool isLoading = true;

  Set<TaskStatus> activeStatusFilters = {};
  Set<Priority> activePriorityFilters = {};
  Set<Tag> activeTagFilters = {};
  String? activeDueBucket;
  String? activeSort;

  late final List<Tag> allTags;
  late final List<Project> projects;

  @override
  void initState() {
    super.initState();

    allTags = [
      Tag(id: "1", label: "UI", colorHex: 0xFF4F46E5),
      Tag(id: "2", label: "UX", colorHex: 0xFF6366F1),
      Tag(id: "3", label: "Board", colorHex: 0xFF10B981),
      Tag(id: "4", label: "Backend", colorHex: 0xFFF59E0B),
      Tag(id: "5", label: "API", colorHex: 0xFFEF4444),
    ];

    projects = [
      Project(
        name: "Task MVP",
        tasks: [
          Task(
            id: "1",
            title: "Design UI",
            important: true,
            dueDate: DateTime.now(),
            priority: Priority.high,
            status: TaskStatus.todo,
            tags: [allTags[0]],
          ),
          Task(
            id: "2",
            title: "Filters UX",
            status: TaskStatus.inProgress,
            priority: Priority.medium,
            tags: [allTags[1]],
          ),
          Task(
            id: "3",
            title: "Board Polish",
            status: TaskStatus.done,
            priority: Priority.low,
            tags: [allTags[2]],
          ),
        ],
      ),
    ];

    Timer(const Duration(seconds: 1), () {
      setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = projects.map((p) {
      final tasks = p.tasks.where((t) {
        final matchesSearch =
        t.title.toLowerCase().contains(searchQuery.toLowerCase());
        final matchesStatus =
            activeStatusFilters.isEmpty ||
                activeStatusFilters.contains(t.status);
        final matchesPriority =
            activePriorityFilters.isEmpty ||
                activePriorityFilters.contains(t.priority);
        final matchesTag =
            activeTagFilters.isEmpty ||
                t.tags.any((tag) => activeTagFilters.contains(tag));
        final matchesDue = _matchesDueBucket(t);
        return matchesSearch &&
            matchesStatus &&
            matchesPriority &&
            matchesTag &&
            matchesDue;
      }).toList();

      return Project(name: p.name, tasks: tasks);
    }).where((p) =>
    p.tasks.isNotEmpty ||
        p.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    final todayCount = projects
        .expand((p) => p.tasks)
        .where((t) => t.dueDate != null && _isToday(t.dueDate!))
        .length;

    final overdueCount = projects
        .expand((p) => p.tasks)
        .where((t) =>
    t.dueDate != null && t.dueDate!.isBefore(DateTime.now()))
        .length;

    final upcomingCount = projects
        .expand((p) => p.tasks)
        .where((t) =>
    t.dueDate != null && t.dueDate!.isAfter(DateTime.now()))
        .length;

    final completedCount = projects
        .expand((p) => p.tasks)
        .where((t) => t.status == TaskStatus.done)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SettingsScreen(onToggleTheme: widget.onToggleTheme),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openTaskBottomSheet(
          context: context,
          projects: projects,
          onUpdate: () => setState(() {}),
        ),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 🔍 PREMIUM SEARCH BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color:Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) =>
                        setState(() => searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: "Search tasks or projects",
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => searchQuery = ""),
                    child: const Icon(Icons.close,
                        size: 18, color: Colors.grey),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// 📊 SUMMARY CARDS (VERTICAL)
          _summaryCard("Today", todayCount, AppColors.todayGradient),
          const SizedBox(height: 8),
          _summaryCard("Overdue", overdueCount, AppColors.overdueGradient),
          const SizedBox(height: 8),
          _summaryCard("Upcoming", upcomingCount, AppColors.upcomingGradient),
          const SizedBox(height: 8),
          _summaryCard("Completed", completedCount, AppColors.completedGradient),

          const SizedBox(height: 24),

          /// 📁 PROJECTS HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Projects",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => openFilterBottomSheet(
                  context: context,
                  allTags: allTags,
                  statusFilters: activeStatusFilters,
                  priorityFilters: activePriorityFilters,
                  tagFilters: activeTagFilters,
                  dueBucket: activeDueBucket,
                  sort: activeSort,
                  onApply: (s, p, t, d, so) {
                    setState(() {
                      activeStatusFilters = s;
                      activePriorityFilters = p;
                      activeTagFilters = t;
                      activeDueBucket = d;
                      activeSort = so;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (isLoading)
            ...List.generate(2, (_) => const ProjectSkeleton())
          else if (filteredProjects.isEmpty)
            EmptyState(
              title: "No projects found",
              subtitle: "Try adjusting search or filters",
              buttonText: "Clear",
              onPressed: () => setState(() {
                searchQuery = "";
                activeStatusFilters.clear();
                activePriorityFilters.clear();
                activeTagFilters.clear();
              }),
            )
          else
            ...filteredProjects.map(
                  (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProjectCardImproved(
                  project: p,
                  onOpenBoard: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BoardScreen(project: p),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, int count, LinearGradient gradient) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  bool _matchesDueBucket(Task task) {
    if (activeDueBucket == null || task.dueDate == null) return true;
    final now = DateTime.now();

    switch (activeDueBucket) {
      case "Today":
        return _isToday(task.dueDate!);
      case "Overdue":
        return task.dueDate!.isBefore(now);
      case "Next 7 Days":
        return task.dueDate!
            .isAfter(now) &&
            task.dueDate!.isBefore(now.add(const Duration(days: 7)));
      default:
        return true;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
