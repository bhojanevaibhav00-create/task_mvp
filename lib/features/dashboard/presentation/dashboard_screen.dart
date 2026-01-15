import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

/* ================= APP ROOT ================= */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4F46E5),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      ),
      home: const DashboardScreen(),
    );
  }
}

/* ================= MODELS ================= */

enum TaskStatus { todo, inProgress, done }
enum SortType { az, dueDate, priority }

class Task {
  String title;
  bool completed;
  bool important;
  DateTime? due;
  TaskStatus status;

  Task({
    required this.title,
    this.completed = false,
    this.important = false,
    this.due,
    this.status = TaskStatus.todo,
  });
}

class Project {
  String name;
  List<Task> tasks;
  Project({required this.name, required this.tasks});
}

/* ================= DASHBOARD ================= */

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  String searchQuery = "";

  final List<Project> projects = [
    Project(name: "Task MVP", tasks: [
      Task(title: "Design UI", important: true, due: DateTime.now()),
      Task(title: "Filters UX", status: TaskStatus.inProgress),
      Task(title: "Board Polish", status: TaskStatus.done),
    ])
  ];

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  Widget build(BuildContext context) {
    final filteredProjects = projects.where((p) {
      final projectMatch = p.name.toLowerCase().contains(searchQuery.toLowerCase());
      final taskMatch = p.tasks.any(
            (t) => t.title.toLowerCase().contains(searchQuery.toLowerCase()),
      );
      return projectMatch || taskMatch;
    }).toList();

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search tasks or projects",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          _smartRow(),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Projects",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedList(
              key: _listKey,
              initialItemCount: filteredProjects.length,
              itemBuilder: (context, index, animation) {
                final project = filteredProjects[index];
                return SizeTransition(
                  sizeFactor: animation,
                  child: AnimatedProjectCard(project: project),
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _showAddProjectDialog,
          icon: const Icon(Icons.add),
          label: const Text("Add Project"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _smartRow() => Row(
    children: const [
      Expanded(child: AnimatedSmartTile(icon: Icons.today, label: "My Day")),
      SizedBox(width: 12),
      Expanded(child: AnimatedSmartTile(icon: Icons.star, label: "Important")),
    ],
  );

  void _showAddProjectDialog() {
    final TextEditingController projectController = TextEditingController();
    final List<Map<String, dynamic>> tasksData = [];

    void addTaskField() {
      tasksData.add({
        "titleController": TextEditingController(),
        "due": null,
        "important": false,
      });
    }

    addTaskField();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Add Project"),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: projectController,
                      decoration: const InputDecoration(hintText: "Project Name"),
                    ),
                    const SizedBox(height: 12),
                    ...tasksData.asMap().entries.map((entry) {
                      int index = entry.key;
                      var data = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: data["titleController"],
                                decoration: const InputDecoration(hintText: "Task Title"),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(Icons.calendar_today,
                                  color: data["due"] == null ? Colors.grey : Colors.blue),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) setDialogState(() => data["due"] = picked);
                              },
                            ),
                            IconButton(
                              icon: Icon(data["important"] ? Icons.star : Icons.star_border,
                                  color: Colors.amber),
                              onPressed: () {
                                setDialogState(() => data["important"] = !data["important"]);
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () => setDialogState(addTaskField),
                      icon: const Icon(Icons.add),
                      label: const Text("Add Task"),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  if (projectController.text.trim().isEmpty) return;
                  final newTasks = tasksData
                      .map((d) => Task(
                    title: d["titleController"].text.trim(),
                    due: d["due"],
                    important: d["important"],
                  ))
                      .where((t) => t.title.isNotEmpty)
                      .toList();

                  final newProject =
                  Project(name: projectController.text.trim(), tasks: newTasks);

                  setState(() {
                    projects.add(newProject);
                    _listKey.currentState?.insertItem(projects.length - 1,
                        duration: const Duration(milliseconds: 300));
                  });

                  Navigator.pop(context);
                },
                child: const Text("Add Project"),
              ),
            ],
          );
        },
      ),
    );
  }
}

/* ================= SMART TILE ================= */
class AnimatedSmartTile extends StatefulWidget {
  final IconData icon;
  final String label;
  const AnimatedSmartTile({required this.icon, required this.label, super.key});

  @override
  State<AnimatedSmartTile> createState() => _AnimatedSmartTileState();
}

class _AnimatedSmartTileState extends State<AnimatedSmartTile> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      child: AnimatedScale(
        scale: pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: pressed ? 1 : 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(widget.icon, color: Colors.indigo),
                const SizedBox(height: 6),
                Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ================= PROJECT CARD ================= */

class AnimatedProjectCard extends StatefulWidget {
  final Project project;
  const AnimatedProjectCard({required this.project, super.key});

  @override
  State<AnimatedProjectCard> createState() => _AnimatedProjectCardState();
}

class _AnimatedProjectCardState extends State<AnimatedProjectCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectScreen(project: widget.project),
        ),
      ),
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: pressed ? 2 : 6,
          child: ListTile(
            title: Text(widget.project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${widget.project.tasks.length} tasks"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ),
      ),
    );
  }
}

/* ================= PROJECT SCREEN ================= */

class ProjectScreen extends StatefulWidget {
  final Project project;
  const ProjectScreen({super.key, required this.project});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  TaskStatus? statusFilter;
  bool importantOnly = false;
  SortType sort = SortType.az;

  final GlobalKey<AnimatedListState> _taskListKey = GlobalKey<AnimatedListState>();

  List<Task> get filteredTasks {
    List<Task> list = [...widget.project.tasks];

    if (statusFilter != null) list = list.where((t) => t.status == statusFilter).toList();
    if (importantOnly) list = list.where((t) => t.important).toList();

    switch (sort) {
      case SortType.az:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortType.dueDate:
        list.sort((a, b) => (a.due ?? DateTime(2100)).compareTo(b.due ?? DateTime(2100)));
        break;
      case SortType.priority:
        list.sort((a, b) => b.important ? 1 : -1);
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _openFilters),
          IconButton(
            icon: const Icon(Icons.view_kanban),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BoardScreen(tasks: filteredTasks),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _activeFilters(),
          Expanded(
            child: AnimatedList(
              key: _taskListKey,
              initialItemCount: filteredTasks.length,
              itemBuilder: (context, index, animation) {
                final task = filteredTasks[index];
                return SizeTransition(
                  sizeFactor: animation,
                  child: AnimatedTaskCard(
                    task: task,
                    onUpdate: () => setState(() {}),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeFilters() {
    if (statusFilter == null && !importantOnly) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (statusFilter != null)
            Chip(label: Text(statusFilter!.name), onDeleted: () => setState(() => statusFilter = null)),
          if (importantOnly) Chip(label: const Text("Important"), onDeleted: () => setState(() => importantOnly = false)),
          ActionChip(
            label: const Text("Clear"),
            onPressed: () {
              setState(() {
                statusFilter = null;
                importantOnly = false;
              });
            },
          )
        ],
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Filters", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: TaskStatus.values.map((s) {
                return ChoiceChip(
                  label: Text(s.name),
                  selected: statusFilter == s,
                  onSelected: (_) => setState(() => statusFilter = s),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            FilterChip(label: const Text("Important"), selected: importantOnly, onSelected: (v) => setState(() => importantOnly = v)),
            const SizedBox(height: 8),
            DropdownButton<SortType>(
              value: sort,
              items: const [
                DropdownMenuItem(value: SortType.az, child: Text("A–Z")),
                DropdownMenuItem(value: SortType.dueDate, child: Text("Due Date")),
                DropdownMenuItem(value: SortType.priority, child: Text("Priority")),
              ],
              onChanged: (v) => setState(() => sort = v!),
            )
          ],
        ),
      ),
    );
  }
}

/* ================= TASK CARD ================= */

class AnimatedTaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onUpdate;
  const AnimatedTaskCard({super.key, required this.task, required this.onUpdate});

  @override
  State<AnimatedTaskCard> createState() => _AnimatedTaskCardState();
}

class _AnimatedTaskCardState extends State<AnimatedTaskCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.task;

    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: pressed ? 2 : 4,
          child: ListTile(
            leading: Checkbox(
              value: t.completed,
              onChanged: (v) {
                t.completed = v!;
                widget.onUpdate();
              },
            ),
            title: Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: t.due != null ? Text(DateFormat('dd MMM').format(t.due!)) : null,
            trailing: IconButton(
              icon: Icon(t.important ? Icons.star : Icons.star_border, color: Colors.amber),
              onPressed: () {
                t.important = !t.important;
                widget.onUpdate();
              },
            ),
          ),
        ),
      ),
    );
  }
}

/* ================= BOARD ================= */

class BoardScreen extends StatelessWidget {
  final List<Task> tasks;
  const BoardScreen({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Board")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: tasks.map((t) => AnimatedTaskCard(task: t, onUpdate: () {})).toList(),
      ),
    );
  }
}
