import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

/* ================= DESIGN SYSTEM ================= */
class AppTheme {
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF6366F1);

  static const Color surfaceLight = Color(0xFFF4F6FA);
  static const Color surfaceDark = Color(0xFF121212);

  static const double radius = 16;
  static const double elevation = 1.5;
}

/* ================= APP ROOT ================= */
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task MVP',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,

      /* ================= LIGHT THEME ================= */
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primary,
          brightness: Brightness.light,
          surface: AppTheme.surfaceLight,
        ),
        scaffoldBackgroundColor: AppTheme.surfaceLight,

        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),

        cardTheme: CardTheme(
          elevation: AppTheme.elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
        ),

        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
        ),
      ),

      /* ================= DARK THEME ================= */
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryDark,
          brightness: Brightness.dark,
          surface: AppTheme.surfaceDark,
        ),
        scaffoldBackgroundColor: AppTheme.surfaceDark,

        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),

        cardTheme: CardTheme(
          color: const Color(0xFF1E1E1E),
          elevation: AppTheme.elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF2A2A2A),
          selectedColor: AppTheme.primaryDark,
          labelStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppTheme.primaryDark,
          foregroundColor: Colors.white,
        ),
      ),

      home: DashboardScreen(onToggleTheme: _toggleTheme),
    );
  }
}

/* ================= MODELS ================= */
enum TaskStatus { todo, inProgress, done }
enum TaskPriority { low, medium, high }

class Task {
  String title;
  bool completed;
  bool important;
  DateTime? due;
  TaskStatus status;
  TaskPriority priority;
  List<String> tags;

  Task({
    required this.title,
    this.completed = false,
    this.important = false,
    this.due,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.tags = const [],
  });
}

class Project {
  String name;
  List<Task> tasks;
  Project({required this.name, required this.tasks});
}

/* ================= DASHBOARD ================= */
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
  Set<TaskPriority> activePriorityFilters = {};
  Set<String> activeTagFilters = {};
  String? activeDueBucket;
  String? activeSort;

  final List<String> allTags = ["UI", "UX", "Board", "Backend", "API"];

  final List<Project> projects = [
    Project(name: "Task MVP", tasks: [
      Task(title: "Design UI", important: true, due: DateTime.now(), priority: TaskPriority.high, tags: ["UI"]),
      Task(title: "Filters UX", status: TaskStatus.inProgress, priority: TaskPriority.medium, tags: ["UX"]),
      Task(title: "Board Polish", status: TaskStatus.done, priority: TaskPriority.low, tags: ["Board"]),
    ])
  ];

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Project> filteredProjects = projects.map((project) {
      final filteredTasks = project.tasks.where((task) {
        final matchesSearch = task.title.toLowerCase().contains(searchQuery.toLowerCase());
        final matchesStatus = activeStatusFilters.isEmpty || activeStatusFilters.contains(task.status);
        final matchesPriority = activePriorityFilters.isEmpty || activePriorityFilters.contains(task.priority);
        final matchesTag = activeTagFilters.isEmpty || task.tags.any((t) => activeTagFilters.contains(t));
        final matchesDue = _matchesDueBucket(task);
        return matchesSearch && matchesStatus && matchesPriority && matchesTag && matchesDue;
      }).toList();
      final sortedTasks = _sortTasks(filteredTasks);
      return Project(name: project.name, tasks: sortedTasks);
    }).where((p) => p.tasks.isNotEmpty || p.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen(onToggleTheme: widget.onToggleTheme)),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskBottomSheet(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isLoading)
            ...List.generate(2, (_) => const ProjectSkeleton())
          else
            for (var p in filteredProjects) AnimatedProjectCard(project: p),
        ],
      ),
    );
  }

  bool _matchesDueBucket(Task task) {
    if (activeDueBucket == null) return true;
    final now = DateTime.now();
    if (task.due == null) return false;
    switch (activeDueBucket) {
      case "Today":
        return task.due!.year == now.year &&
            task.due!.month == now.month &&
            task.due!.day == now.day;
      case "Overdue":
        return task.due!.isBefore(now);
      case "Next 7 Days":
        return task.due!.isAfter(now) && task.due!.isBefore(now.add(const Duration(days: 7)));
      default:
        return true;
    }
  }

  List<Task> _sortTasks(List<Task> tasks) {
    switch (activeSort) {
      case "A-Z":
        tasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case "Due Date":
        tasks.sort((a, b) {
          if (a.due == null && b.due == null) return 0;
          if (a.due == null) return 1;
          if (b.due == null) return -1;
          return a.due!.compareTo(b.due!);
        });
        break;
      case "Priority":
        tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
    }
    return tasks;
  }

  void _openTaskBottomSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, decoration: const InputDecoration(labelText: "Task Title")),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() => projects.first.tasks.add(Task(title: controller.text)));
                Navigator.pop(context);
              },
              child: const Text("Create Task"),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= SETTINGS ================= */
class SettingsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  const SettingsScreen({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SwitchListTile(
        title: const Text("Dark Mode"),
        value: Theme.of(context).brightness == Brightness.dark,
        onChanged: (_) => onToggleTheme(),
      ),
    );
  }
}

/* ================= UI COMPONENTS ================= */
class AnimatedProjectCard extends StatelessWidget {
  final Project project;
  const AnimatedProjectCard({required this.project, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(project.name),
        subtitle: Text("${project.tasks.length} tasks"),
      ),
    );
  }
}

class ProjectSkeleton extends StatelessWidget {
  const ProjectSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Container(height: 16, color: Colors.grey),
        subtitle: Container(height: 12, color: Colors.grey[300]),
      ),
    );
  }
}
