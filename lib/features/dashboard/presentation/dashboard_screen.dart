import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ================= DOMAIN MODELS =================
class Task {
  String title;
  DateTime? dueDate;
  bool isCompleted;
  bool isImportant;
  List<String> tags;

  Task({
    required this.title,
    this.dueDate,
    this.isCompleted = false,
    this.isImportant = false,
    this.tags = const [],
  });
}

class Project {
  String name;
  List<Task> tasks;

  Project({required this.name, this.tasks = const []});

  double get progress =>
      tasks.isEmpty ? 0 : tasks.where((t) => t.isCompleted).length / tasks.length;
}

// ================= ENUMS =================
enum SmartListType { myDay, important, planned, all }
enum TaskStatus { all, completed, pending }

// ================= DASHBOARD SCREEN =================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final List<Task> _tasks = [];
  final List<Project> _projects = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========== HEADER ==========
  Widget _buildHeader() {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("👋 Welcome ",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(DateFormat('dd/MM/yyyy').format(now),
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NotificationsScreen(tasks: _tasks))),
          ),
        ],
      ),
    );
  }

  // ========== SEARCH ==========
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search tasks/projects",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  // ========== SMART LIST TILE ==========
  Widget _smartTile(String title, IconData icon, Color color, SmartListType type) {
    int count = 0;
    final now = DateTime.now();
    switch (type) {
      case SmartListType.myDay:
        count = _tasks
            .where((t) =>
        t.dueDate != null &&
            t.dueDate!.day == now.day &&
            t.dueDate!.month == now.month &&
            t.dueDate!.year == now.year)
            .length;
        break;
      case SmartListType.important:
        count = _tasks.where((t) => t.isImportant).length;
        break;
      case SmartListType.planned:
        count = _tasks.where((t) => t.dueDate != null).length;
        break;
      case SmartListType.all:
        count = _tasks.length;
        break;
    }

    return GestureDetector(
      onTap: () => _openSmartList(type, title),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))
            ]),
        child: ListTile(
          leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: CircleAvatar(
              radius: 14,
              backgroundColor: color.withOpacity(0.2),
              child: Text(count.toString(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  void _openSmartList(SmartListType type, String title) {
    final filtered = _tasks;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => SmartListSheet(
          tasks: filtered,
          title: title,
          onUpdate: () => setState(() {}),
          addTaskCallback: (task) {
            _tasks.add(task);
            setState(() {});
          },
          deleteTaskCallback: (task) {
            _tasks.remove(task);
            setState(() {});
          },
        ));
  }

  // ========== HOME ==========
  Widget _buildHome() {
    final now = DateTime.now();
    final todayTasks = _tasks
        .where((t) =>
    t.dueDate != null &&
        t.dueDate!.day == now.day &&
        t.dueDate!.month == now.month &&
        t.dueDate!.year == now.year)
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearch(),
          const SizedBox(height: 12),

          // ===== MY DAY IMPROVED =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "My Day - ${DateFormat('EEEE, dd MMM yyyy').format(now)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (todayTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("No tasks for today!", style: TextStyle(color: Colors.grey)),
            )
          else
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: todayTasks.length,
              itemBuilder: (_, i) {
                final task = todayTasks[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (v) => setState(() => task.isCompleted = v!)),
                    title: Text(task.title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration:
                            task.isCompleted ? TextDecoration.lineThrough : null)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (task.isImportant)
                          const Icon(Icons.star, color: Colors.amber),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() => _tasks.remove(task));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          // ===== OTHER SMART LISTS =====
          _smartTile("Important", Icons.star, Colors.amber, SmartListType.important),
          _smartTile("Planned", Icons.calendar_today, Colors.purple, SmartListType.planned),
          _smartTile("All Tasks", Icons.task_alt, Colors.green, SmartListType.all),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ========== PROJECTS ==========
  Widget _projectsScreen() => ProjectsScreen(projects: _projects);

  // ========== PROFILE ==========
  Widget _profileScreen() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
        SizedBox(height: 8),
        Text("Profile Placeholder", style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _buildBottomNav() => BottomNavigationBar(
    currentIndex: _currentIndex,
    onTap: (i) => setState(() => _currentIndex = i),
    selectedItemColor: const Color(0xFF6366F1),
    unselectedItemColor: Colors.grey,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
      BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: "Projects"),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final pages = [_buildHome(), _projectsScreen(), _profileScreen()];
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(child: IndexedStack(index: _currentIndex, children: pages)),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}

// ================= SMART LIST SHEET =================
class SmartListSheet extends StatefulWidget {
  final String title;
  final List<Task> tasks;
  final VoidCallback onUpdate;
  final Function(Task) addTaskCallback;
  final Function(Task) deleteTaskCallback;

  const SmartListSheet(
      {super.key,
        required this.title,
        required this.tasks,
        required this.onUpdate,
        required this.addTaskCallback,
        required this.deleteTaskCallback});

  @override
  State<SmartListSheet> createState() => _SmartListSheetState();
}

class _SmartListSheetState extends State<SmartListSheet> {
  TaskStatus selectedStatus = TaskStatus.all;
  bool filterImportant = false;

  List<Task> get filteredTasks {
    var temp = widget.tasks;
    if (selectedStatus != TaskStatus.all)
      temp = temp
          .where((t) => selectedStatus == TaskStatus.completed ? t.isCompleted : !t.isCompleted)
          .toList();
    if (filterImportant) temp = temp.where((t) => t.isImportant).toList();
    return temp;
  }

  void _openAddTaskSheet() {
    final controller = TextEditingController();
    DateTime? dueDate;
    bool isImportant = false;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add Task",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                      hintText: "Task Title", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100));
                          if (picked != null) {
                            dueDate = picked;
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(dueDate == null
                            ? "Set Due Date"
                            : DateFormat('dd/MM/yyyy').format(dueDate!)))),
                const SizedBox(width: 12),
                Checkbox(value: isImportant, onChanged: (v) => setState(() => isImportant = v!)),
                const Text("Important")
              ]),
              const SizedBox(height: 12),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        if (controller.text.trim().isEmpty) return;
                        final task = Task(
                            title: controller.text.trim(),
                            dueDate: dueDate,
                            isImportant: isImportant);
                        widget.addTaskCallback(task);
                        Navigator.pop(context);
                      },
                      child: const Text("Add Task")))
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(children: [
              Text(widget.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              ElevatedButton.icon(
                  onPressed: _openAddTaskSheet, icon: const Icon(Icons.add), label: const Text("Add Task"))
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                    label: const Text("All"),
                    selected: selectedStatus == TaskStatus.all,
                    onSelected: (_) => setState(() => selectedStatus = TaskStatus.all)),
                ChoiceChip(
                    label: const Text("Completed"),
                    selected: selectedStatus == TaskStatus.completed,
                    onSelected: (_) => setState(() => selectedStatus = TaskStatus.completed)),
                ChoiceChip(
                    label: const Text("Pending"),
                    selected: selectedStatus == TaskStatus.pending,
                    onSelected: (_) => setState(() => selectedStatus = TaskStatus.pending)),
                FilterChip(
                    label: const Text("Important"),
                    selected: filterImportant,
                    onSelected: (v) => setState(() => filterImportant = v)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
                child: filteredTasks.isEmpty
                    ? const Center(child: Text("No tasks"))
                    : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (_, i) {
                      final task = filteredTasks[i];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                              value: task.isCompleted,
                              onChanged: (v) {
                                task.isCompleted = v!;
                                widget.onUpdate();
                              }),
                          title: Text(task.title,
                              style: TextStyle(
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Row(children: [
                            if (task.dueDate != null)
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                      DateFormat('dd/MM/yyyy').format(task.dueDate!),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.blue))),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: task.isImportant
                                        ? Colors.amber.shade100
                                        : Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(task.isImportant ? "Important" : "Normal"))
                          ]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              widget.deleteTaskCallback(task);
                            },
                          ),
                        ),
                      );
                    }))
          ],
        ),
      ),
    );
  }
}

// ================= NOTIFICATIONS SCREEN =================
class NotificationsScreen extends StatelessWidget {
  final List<Task> tasks;
  const NotificationsScreen({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final unread = tasks.where((t) => !t.isCompleted).toList();
    return Scaffold(
      appBar: AppBar(
          title: const Text("Notifications"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black),
      body: unread.isEmpty
          ? const Center(child: Text("No notifications"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: unread.length,
        itemBuilder: (_, i) {
          final t = unread[i];
          return Card(
              child: ListTile(
                  title: Text(t.title),
                  subtitle: Text(t.isImportant ? "Important" : "Normal"),
                  onTap: () => Navigator.pop(context)));
        },
      ),
    );
  }
}

// ================= PROJECTS SCREEN =================
class ProjectsScreen extends StatefulWidget {
  final List<Project> projects;
  const ProjectsScreen({super.key, required this.projects});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final filteredProjects = widget.projects
        .where((p) => p.name.toLowerCase().contains(_searchController.text.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Projects"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // ===== Search + New Project =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search projects",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Add new project
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("New Project"),
                ),
              ],
            ),
          ),

          // ===== Empty state =====
          if (widget.projects.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.folder_open, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("Create your first project",
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
          // ===== Project list =====
            Expanded(
              child: ListView.builder(
                itemCount: filteredProjects.length,
                itemBuilder: (_, i) {
                  final project = filteredProjects[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: LinearProgressIndicator(value: project.progress),
                      trailing: PopupMenuButton(
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text("Edit")),
                          const PopupMenuItem(value: 'archive', child: Text("Archive")),
                        ],
                        onSelected: (v) {},
                      ),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProjectDetailsScreen(project: project))),
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

// ================= PROJECT DETAILS =================
class ProjectDetailsScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(text: "Overview"),
          Tab(text: "Tasks"),
          Tab(text: "Activity"),
        ]),
      ),
      body: TabBarView(controller: _tabController, children: [
        // ===== Overview =====
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Progress", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: widget.project.progress),
              const SizedBox(height: 16),
              Text("Upcoming Tasks", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (widget.project.tasks.isEmpty)
                const Text("No upcoming tasks")
              else
                ...widget.project.tasks
                    .take(3)
                    .map((t) => ListTile(
                  title: Text(t.title),
                  subtitle: t.dueDate != null
                      ? Text(DateFormat('dd/MM/yyyy').format(t.dueDate!))
                      : null,
                  trailing: t.isImportant
                      ? const Icon(Icons.star, color: Colors.amber)
                      : null,
                ))
                    .toList(),
            ],
          ),
        ),

        // ===== Tasks Tab =====
        Center(child: Text("Tasks Tab")),

        // ===== Activity Tab =====
        Center(child: Text("Activity Tab")),
      ]),
    );
  }
}
