import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/tag_model.dart';
import 'package:task_mvp/features/dashboard/presentation//widgets/project_card_improved.dart';
import 'package:task_mvp/features/dashboard/presentation//widgets/animated_project_card.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/project_skeleton.dart';
import 'package:task_mvp/features/dashboard/presentation//widgets/empty_state.dart';
import 'board_screen.dart';
import 'settings_screen.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/task_bottom_sheet.dart';

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

    // Define tags
    allTags = [
      Tag(id: "1", label: "UI", colorHex: 0xFF4F46E5),
      Tag(id: "2", label: "UX", colorHex: 0xFF6366F1),
      Tag(id: "3", label: "Board", colorHex: 0xFF10B981),
      Tag(id: "4", label: "Backend", colorHex: 0xFFF59E0B),
      Tag(id: "5", label: "API", colorHex: 0xFFEF4444),
    ];

    // Sample projects & tasks
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
              tags: [allTags[0]]),
          Task(
              id: "2",
              title: "Filters UX",
              status: TaskStatus.inProgress,
              priority: Priority.medium,
              tags: [allTags[1]]),
          Task(
              id: "3",
              title: "Board Polish",
              status: TaskStatus.done,
              priority: Priority.low,
              tags: [allTags[2]]),
          Task(
              id: "4",
              title: "API Integration",
              status: TaskStatus.todo,
              priority: Priority.high,
              tags: [allTags[3], allTags[4]]),
        ],
      ),
    ];

    // Simulate loading
    Timer(const Duration(seconds: 2), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter & sort projects/tasks
    List<Project> filteredProjects = projects.map((project) {
      final filteredTasks = project.tasks.where((task) {
        final matchesSearch =
        task.title.toLowerCase().contains(searchQuery.toLowerCase());
        final matchesStatus =
            activeStatusFilters.isEmpty || activeStatusFilters.contains(task.status);
        final matchesPriority = activePriorityFilters.isEmpty ||
            activePriorityFilters.contains(task.priority);
        final matchesTag = activeTagFilters.isEmpty ||
            task.tags.any((t) => activeTagFilters.contains(t));
        final matchesDue = _matchesDueBucket(task);
        return matchesSearch && matchesStatus && matchesPriority && matchesTag && matchesDue;
      }).toList();

      return Project(name: project.name, tasks: filteredTasks);
    }).where((p) => p.tasks.isNotEmpty || p.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    // Summary cards counts
    final todayCount = projects
        .expand((p) => p.tasks)
        .where((t) => t.dueDate != null && isToday(t.dueDate!))
        .length;
    final overdueCount = projects
        .expand((p) => p.tasks)
        .where((t) => t.dueDate != null && t.dueDate!.isBefore(DateTime.now()))
        .length;
    final upcomingCount = projects
        .expand((p) => p.tasks)
        .where((t) => t.dueDate != null && t.dueDate!.isAfter(DateTime.now()))
        .length;
    final completedCount = projects
        .expand((p) => p.tasks)
        .where((t) => t.status == TaskStatus.done)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text("No new notifications"))),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SettingsScreen(onToggleTheme: widget.onToggleTheme)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            openTaskBottomSheet(context: context, projects: projects, onUpdate: () => setState(() {})),
        child: const Icon(Icons.add),
        backgroundColor: AppColors.fabBackground,
        foregroundColor: AppColors.fabForeground,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search
          TextField(
            onChanged: (v) => setState(() => searchQuery = v),
            decoration: InputDecoration(
              hintText: "Search tasks or projects",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppColors.cardRadius), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          // Summary Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryCard("Today", todayCount, AppColors.todayGradient),
              _summaryCard("Overdue", overdueCount, AppColors.overdueGradient),
              _summaryCard("Upcoming", upcomingCount, AppColors.upcomingGradient),
              _summaryCard("Completed", completedCount, AppColors.completedGradient),
            ],
          ),
          const SizedBox(height: 16),

          // Projects Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Projects", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    onApply: (status, priority, tags, due, sort) {
                      setState(() {
                        activeStatusFilters = status;
                        activePriorityFilters = priority;
                        activeTagFilters = tags;
                        activeDueBucket = due;
                        activeSort = sort;
                      });
                    },
                  )),
            ],
          ),
          const SizedBox(height: 8),

          // Projects / Loading / Empty
          if (isLoading)
            ...List.generate(2, (index) => const ProjectSkeleton())
          else if (filteredProjects.isEmpty)
            EmptyState(
              title: "No projects yet",
              subtitle: "Create your first project",
              buttonText: "Add Project",
              onPressed: () {},
            )
          else
            for (var p in filteredProjects)
              Column(
                children: [
                  ProjectCardImproved(project: p, onOpenBoard: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => BoardScreen(project: p)));
                  }),
                  const SizedBox(height: 12),
                ],
              ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, int count, LinearGradient gradient) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  bool _matchesDueBucket(Task task) {
    if (activeDueBucket == null) return true;
    final now = DateTime.now();
    if (task.dueDate == null) return false;
    switch (activeDueBucket) {
      case "Today":
        return isToday(task.dueDate!);
      case "Overdue":
        return task.dueDate!.isBefore(now);
      case "Next 7 Days":
        return task.dueDate!.isAfter(now) && task.dueDate!.isBefore(now.add(const Duration(days: 7)));
      default:
        return true;
    }
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
