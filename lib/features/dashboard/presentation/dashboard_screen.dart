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

// ================= ENUMS =================
enum SmartListType { myDay, important, planned, all }
enum TaskSort { dueDate, priority, title }
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

  bool _isBoardView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "👋 Welcome, Vaishnavi",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('dd/MM/yyyy').format(now),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          NotificationsScreen(tasks: _tasks)));
            },
          ),
        ],
      ),
    );
  }

  // ================= SEARCH =================
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
        onChanged: (val) => setState(() {}),
      ),
    );
  }

  // ================= SMART LIST TILES =================
  Widget _smartTile(String title, IconData icon, Color color, SmartListType type) {
    final now = DateTime.now();
    int count = 0;

    switch (type) {
      case SmartListType.myDay:
        count = _tasks.where((t) {
          final d = t.dueDate;
          return d != null &&
              d.day == now.day &&
              d.month == now.month &&
              d.year == now.year;
        }).length;
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
      onTap: () {
        _openSmartList(type, title);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          trailing: CircleAvatar(
            radius: 14,
            backgroundColor: color.withOpacity(0.15),
            child: Text(count.toString(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  void _openSmartList(SmartListType type, String title) {
    final List<Task> filtered = _getTasksForSmartList(type);
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
            }));
  }

  List<Task> _getTasksForSmartList(SmartListType type) {
    final now = DateTime.now();
    switch (type) {
      case SmartListType.myDay:
        return _tasks
            .where((t) =>
        t.dueDate != null &&
            t.dueDate!.day == now.day &&
            t.dueDate!.month == now.month &&
            t.dueDate!.year == now.year)
            .toList();
      case SmartListType.important:
        return _tasks.where((t) => t.isImportant).toList();
      case SmartListType.planned:
        return _tasks.where((t) => t.dueDate != null).toList();
      case SmartListType.all:
        return _tasks;
    }
  }

  // ================= DASHBOARD HOME =================
  Widget _buildHome() => Column(
    children: [
      _buildHeader(),
      _buildSearch(),
      _smartTile("My Day", Icons.today, Colors.blue, SmartListType.myDay),
      _smartTile("Important", Icons.star, Colors.amber, SmartListType.important),
      _smartTile("Planned", Icons.calendar_today, Colors.purple, SmartListType.planned),
      _smartTile("All Tasks", Icons.task_alt, Colors.green, SmartListType.all),
      Expanded(child: Container()), // Task section placeholder
    ],
  );

  // ================= PROJECTS SCREEN =================
  Widget _projectsScreen() => const Center(child: Text("Projects Placeholder"));

  // ================= PROFILE SCREEN =================
  Widget _profileScreen() => const Center(child: Text("Profile Placeholder"));

  Widget _buildBottomNav() => BottomNavigationBar(
    currentIndex: _currentIndex,
    onTap: (index) => setState(() => _currentIndex = index),
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

// ================= SMART LIST SHEET WITH FILTERS & ADD TASK =================
class SmartListSheet extends StatefulWidget {
  final String title;
  final List<Task> tasks;
  final VoidCallback onUpdate;
  final Function(Task) addTaskCallback;

  const SmartListSheet(
      {super.key,
        required this.title,
        required this.tasks,
        required this.onUpdate,
        required this.addTaskCallback});

  @override
  State<SmartListSheet> createState() => _SmartListSheetState();
}

class _SmartListSheetState extends State<SmartListSheet> {
  TaskStatus selectedStatus = TaskStatus.all;
  bool filterImportant = false;

  List<Task> get filteredTasks {
    List<Task> temp = widget.tasks;
    if (selectedStatus != TaskStatus.all) {
      temp = temp.where((t) {
        final completed = t.isCompleted;
        return selectedStatus == TaskStatus.completed ? completed : !completed;
      }).toList();
    }
    if (filterImportant) {
      temp = temp.where((t) => t.isImportant).toList();
    }
    return temp;
  }

  void _openAddTaskSheet() {
    final titleController = TextEditingController();
    DateTime? dueDate;
    bool isImportant = false;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add Task",
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration:
                const InputDecoration(hintText: "Task Title", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
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
                            : DateFormat('dd/MM/yyyy').format(dueDate!))),
                  ),
                  const SizedBox(width: 12),
                  Checkbox(
                      value: isImportant,
                      onChanged: (v) => setState(() => isImportant = v!)),
                  const Text("Important")
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) return;
                      final task = Task(
                          title: titleController.text.trim(),
                          dueDate: dueDate,
                          isImportant: isImportant);
                      widget.addTaskCallback(task);
                      Navigator.pop(context);
                    },
                    child: const Text("Add Task")),
              )
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
            Row(
              children: [
                Text(widget.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                ElevatedButton.icon(
                    onPressed: _openAddTaskSheet,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Task"))
              ],
            ),
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
                    onSelected: (_) =>
                        setState(() => selectedStatus = TaskStatus.completed)),
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
                    ? Center(child: Text("No tasks"))
                    : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (_, index) {
                      final task = filteredTasks[index];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (val) {
                              task.isCompleted = val!;
                              widget.onUpdate();
                            },
                          ),
                          title: Text(task.title,
                              style: TextStyle(
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Row(
                            children: [
                              if (task.dueDate != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                      DateFormat('dd/MM/yyyy')
                                          .format(task.dueDate!),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.blue)),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: task.isImportant
                                        ? Colors.amber.shade100
                                        : Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(task.isImportant
                                    ? "Important"
                                    : "Normal"),
                              )
                            ],
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
        foregroundColor: Colors.black,
      ),
      body: unread.isEmpty
          ? const Center(child: Text("No notifications"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: unread.length,
        itemBuilder: (_, index) {
          final t = unread[index];
          return Card(
            child: ListTile(
              title: Text(t.title),
              subtitle: Text(t.isImportant ? "Important" : "Normal"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }
}
