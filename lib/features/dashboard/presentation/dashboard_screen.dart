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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = [
      Project(name: "Task MVP", tasks: [
        Task(title: "Design UI", important: true, due: DateTime.now()),
        Task(title: "Filters UX", status: TaskStatus.inProgress),
        Task(title: "Board Polish", status: TaskStatus.done),
      ])
    ];

    return Scaffold(
      appBar: _header(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _smartRow(),
          const SizedBox(height: 16),
          const Text("Projects",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (var p in projects) AnimatedProjectCard(project: p),
        ],
      ),
    );
  }

  AppBar _header() => AppBar(
    title: const Text("Dashboard"),
    centerTitle: true,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
        ),
      ),
    ),
    foregroundColor: Colors.white,
  );

  Widget _smartRow() => Row(
    children: const [
      Expanded(child: AnimatedSmartTile(icon: Icons.today, label: "My Day")),
      SizedBox(width: 12),
      Expanded(child: AnimatedSmartTile(icon: Icons.star, label: "Important")),
    ],
  );
}

/* ================= ANIMATED SMART TILE ================= */

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
                Text(widget.label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ================= ANIMATED PROJECT CARD ================= */

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
            title: Text(widget.project.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
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

  List<Task> get filteredTasks {
    List<Task> list = [...widget.project.tasks];

    if (statusFilter != null) {
      list = list.where((t) => t.status == statusFilter).toList();
    }
    if (importantOnly) {
      list = list.where((t) => t.important).toList();
    }

    switch (sort) {
      case SortType.az:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortType.dueDate:
        list.sort((a, b) =>
            (a.due ?? DateTime(2100)).compareTo(b.due ?? DateTime(2100)));
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
            child: filteredTasks.isEmpty
                ? EmptyState(
              title: "No tasks yet",
              subtitle: "Add tasks to get started",
              buttonText: "Add Task",
              onPressed: () {},
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredTasks.length,
              itemBuilder: (_, i) {
                return AnimatedTaskCard(
                  task: filteredTasks[i],
                  onUpdate: () => setState(() {}),
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
            Chip(
              label: Text(statusFilter!.name),
              onDeleted: () => setState(() => statusFilter = null),
            ),
          if (importantOnly)
            Chip(
              label: const Text("Important"),
              onDeleted: () => setState(() => importantOnly = false),
            ),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Filters",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: TaskStatus.values.map((s) {
                final selected = statusFilter == s;
                return ChoiceChip(
                  label: Text(s.name),
                  selected: selected,
                  onSelected: (_) => setState(() => statusFilter = s),
                  selectedColor: Colors.indigo.shade200,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            FilterChip(
              label: const Text("Important"),
              selected: importantOnly,
              onSelected: (v) => setState(() => importantOnly = v),
            ),
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

/* ================= ANIMATED TASK CARD ================= */

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
            leading: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Checkbox(
                key: ValueKey(t.completed),
                value: t.completed,
                onChanged: (v) {
                  t.completed = v!;
                  widget.onUpdate();
                },
              ),
            ),
            title: Text(
              t.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: t.due != null ? Text(DateFormat('dd MMM').format(t.due!)) : null,
            trailing: IconButton(
              icon: Icon(t.important ? Icons.star : Icons.star_border,
                  color: Colors.amber),
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

class BoardScreen extends StatefulWidget {
  final List<Task> tasks;
  const BoardScreen({super.key, required this.tasks});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  late Map<TaskStatus, List<Task>> columns;

  @override
  void initState() {
    super.initState();
    _initColumns();
  }

  void _initColumns() {
    columns = {
      TaskStatus.todo: widget.tasks.where((t) => t.status == TaskStatus.todo).toList(),
      TaskStatus.inProgress: widget.tasks.where((t) => t.status == TaskStatus.inProgress).toList(),
      TaskStatus.done: widget.tasks.where((t) => t.status == TaskStatus.done).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Board")),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: TaskStatus.values.map((status) {
            final tasks = columns[status]!;
            return Container(
              width: 260,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(status.name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: DragTarget<Task>(
                      onWillAccept: (_) => true,
                      onAccept: (task) {
                        setState(() {
                          columns[task.status]!.remove(task);
                          task.status = status;
                          columns[status]!.add(task);
                        });
                      },
                      builder: (_, candidateData, rejectedData) => ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (_, i) {
                          final t = tasks[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Draggable<Task>(
                              data: t,
                              feedback: Material(
                                child: TaskCardBoard(task: t),
                                elevation: 6,
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: TaskCardBoard(task: t),
                              ),
                              child: TaskCardBoard(task: t),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class TaskCardBoard extends StatelessWidget {
  final Task task;
  const TaskCardBoard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        title: Text(task.title,
            maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            if (task.due != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(DateFormat('dd MMM').format(task.due!), style: const TextStyle(fontSize: 12, color: Colors.blue)),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: task.important ? Colors.amber.shade100 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(task.important ? "Important" : "Normal", style: const TextStyle(fontSize: 12)),
            )
          ],
        ),
      ),
    );
  }
}

/* ================= EMPTY STATE ================= */

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onPressed, child: Text(buttonText))
        ],
      ),
    );
  }
}
