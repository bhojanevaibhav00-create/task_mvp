import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
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
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4F46E5),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6366F1),
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
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // FILTERED PROJECTS BASED ON SEARCH + FILTERS
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
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No new notifications")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    onToggleTheme: widget.onToggleTheme,
                  ),
                ),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskBottomSheet(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// SEARCH
          TextField(
            onChanged: (v) => setState(() => searchQuery = v),
            decoration: InputDecoration(
              hintText: "Search tasks or projects",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          /// SMART TILES
          Row(
            children: const [
              Expanded(child: SmartTile(icon: Icons.today, label: "My Day")),
              SizedBox(width: 12),
              Expanded(child: SmartTile(icon: Icons.star, label: "Important")),
            ],
          ),
          const SizedBox(height: 16),

          /// ACTIVE FILTERS DISPLAY
          if (activeStatusFilters.isNotEmpty ||
              activePriorityFilters.isNotEmpty ||
              activeTagFilters.isNotEmpty ||
              activeDueBucket != null ||
              activeSort != null)
            Wrap(
              spacing: 8,
              children: [
                ...activeStatusFilters.map((s) => FilterChip(
                  label: Text(s.name),
                  selected: true,
                  onSelected: (_) => setState(() => activeStatusFilters.remove(s)),
                )),
                ...activePriorityFilters.map((p) => FilterChip(
                  label: Text(p.name),
                  selected: true,
                  onSelected: (_) => setState(() => activePriorityFilters.remove(p)),
                )),
                ...activeTagFilters.map((t) => FilterChip(
                  label: Text(t),
                  selected: true,
                  onSelected: (_) => setState(() => activeTagFilters.remove(t)),
                )),
                if (activeDueBucket != null)
                  FilterChip(
                    label: Text(activeDueBucket!),
                    selected: true,
                    onSelected: (_) => setState(() => activeDueBucket = null),
                  ),
                if (activeSort != null)
                  FilterChip(
                    label: Text("Sort: $activeSort"),
                    selected: true,
                    onSelected: (_) => setState(() => activeSort = null),
                  ),
                ActionChip(
                  label: const Text("Clear All"),
                  onPressed: () {
                    setState(() {
                      activeStatusFilters.clear();
                      activePriorityFilters.clear();
                      activeTagFilters.clear();
                      activeDueBucket = null;
                      activeSort = null;
                    });
                  },
                ),
              ],
            ),
          const SizedBox(height: 16),

          /// FILTER BUTTON
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Projects", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _openFilterBottomSheet,
              )
            ],
          ),
          const SizedBox(height: 8),

          /// PROJECTS / LOADING
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
                  AnimatedProjectCard(project: p),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => BoardScreen(project: p))),
                    child: const Text("Open Board"),
                  ),
                ],
              ),
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

  void _openFilterBottomSheet() {
    Set<TaskStatus> tempStatus = Set.from(activeStatusFilters);
    Set<TaskPriority> tempPriority = Set.from(activePriorityFilters);
    Set<String> tempTags = Set.from(activeTagFilters);
    String? tempDue = activeDueBucket;
    String? tempSort = activeSort;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return StatefulBuilder(builder: (context, setStateSB) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Filter Tasks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  const Text("Status"),
                  Wrap(
                    spacing: 8,
                    children: TaskStatus.values
                        .map((s) => FilterChip(
                      label: Text(s.name),
                      selected: tempStatus.contains(s),
                      onSelected: (v) =>
                          setStateSB(() => v ? tempStatus.add(s) : tempStatus.remove(s)),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text("Priority"),
                  Wrap(
                    spacing: 8,
                    children: TaskPriority.values
                        .map((p) => FilterChip(
                      label: Text(p.name),
                      selected: tempPriority.contains(p),
                      onSelected: (v) =>
                          setStateSB(() => v ? tempPriority.add(p) : tempPriority.remove(p)),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text("Tags"),
                  Wrap(
                    spacing: 8,
                    children: allTags
                        .map((t) => FilterChip(
                      label: Text(t),
                      selected: tempTags.contains(t),
                      onSelected: (v) =>
                          setStateSB(() => v ? tempTags.add(t) : tempTags.remove(t)),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text("Due"),
                  Wrap(
                    spacing: 8,
                    children: ["Today", "Overdue", "Next 7 Days"]
                        .map((d) => FilterChip(
                      label: Text(d),
                      selected: tempDue == d,
                      onSelected: (v) => setStateSB(() => tempDue = d),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text("Sort"),
                  Wrap(
                    spacing: 8,
                    children: ["A-Z", "Due Date", "Priority"]
                        .map((s) => FilterChip(
                      label: Text(s),
                      selected: tempSort == s,
                      onSelected: (v) => setStateSB(() => tempSort = s),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        activeStatusFilters = tempStatus;
                        activePriorityFilters = tempPriority;
                        activeTagFilters = tempTags;
                        activeDueBucket = tempDue;
                        activeSort = tempSort;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Apply Filters"),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _openTaskBottomSheet({Task? existingTask}) {
    final titleController = TextEditingController(text: existingTask?.title ?? "");
    bool important = existingTask?.important ?? false;
    DateTime? due = existingTask?.due;
    TaskPriority priority = existingTask?.priority ?? TaskPriority.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(builder: (context, setStateSB) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Task Title"),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Important: "),
                  Switch(value: important, onChanged: (v) => setStateSB(() => important = v)),
                ],
              ),
              Row(
                children: [
                  const Text("Priority: "),
                  DropdownButton<TaskPriority>(
                    value: priority,
                    items: TaskPriority.values
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) => setStateSB(() => priority = v!),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text("Due: "),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: due ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setStateSB(() => due = picked);
                    },
                    child: Text(due != null ? DateFormat('MMM dd, yyyy').format(due!) : "Set Date"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isEmpty) return;
                  setState(() {
                    final task = Task(title: titleController.text, important: important, due: due, priority: priority);
                    if (existingTask != null) {
                      existingTask.title = task.title;
                      existingTask.important = task.important;
                      existingTask.due = task.due;
                      existingTask.priority = task.priority;
                    } else {
                      projects.first.tasks.add(task);
                    }
                  });
                  Navigator.pop(context);
                },
                child: Text(existingTask == null ? "Create Task" : "Update Task"),
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
      ),
    );
  }
}

/* ================= SETTINGS SCREEN ================= */
class SettingsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  const SettingsScreen({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (_) => onToggleTheme(),
          ),
          SwitchListTile(
            title: const Text("Notifications"),
            value: true,
            onChanged: (_) {},
          ),
          SwitchListTile(
            title: const Text("Sound"),
            value: false,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}

/* ================= UI COMPONENTS ================= */
class SmartTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const SmartTile({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class AnimatedProjectCard extends StatelessWidget {
  final Project project;
  const AnimatedProjectCard({required this.project, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Container(height: 16, color: Colors.grey[300]),
        subtitle: Container(height: 12, color: Colors.grey[200], margin: const EdgeInsets.only(top: 8)),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;
  const EmptyState({super.key, required this.title, required this.subtitle, required this.buttonText, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(subtitle),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: onPressed, child: Text(buttonText))
      ],
    );
  }
}

/* ================= BOARD SCREEN ================= */
class BoardScreen extends StatefulWidget {
  final Project project;
  const BoardScreen({super.key, required this.project});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  @override
  Widget build(BuildContext context) {
    Map<TaskStatus, List<Task>> grouped = {};
    for (var status in TaskStatus.values) {
      grouped[status] = widget.project.tasks.where((t) => t.status == status).toList();
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.project.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: TaskStatus.values.map((status) {
          final tasks = grouped[status]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(status.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (_, index) {
                  final t = tasks[index];
                  return Card(
                    key: ValueKey(t),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      title: Text(t.title),
                      subtitle: Row(
                        children: [
                          if (t.due != null)
                            Text(DateFormat('MMM dd').format(t.due!), style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          if (t.important) const Icon(Icons.star, size: 14),
                        ],
                      ),
                      trailing: const Icon(Icons.drag_handle),
                      onTap: () {},
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final task = tasks.removeAt(oldIndex);
                    tasks.insert(newIndex, task);
                    final otherTasks = widget.project.tasks.where((t) => t.status != status).toList();
                    widget.project.tasks
                      ..removeWhere((t) => t.status == status)
                      ..addAll(tasks)
                      ..addAll(otherTasks);
                  });
                },
              ),
              const SizedBox(height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }
}
