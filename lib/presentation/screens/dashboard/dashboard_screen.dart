import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  final List<Map<String, String>> tasks = const [
    {
      "title": "Design Login Screen",
      "description": "Create login and signup pages",
      "status": "Todo",
      "priority": "High",
    },
    {
      "title": "Setup Database",
      "description": "Offline-first DB schema",
      "status": "In Progress",
      "priority": "Medium",
    },
    {
      "title": "API Integration",
      "description": "Connect backend APIs",
      "status": "Done",
      "priority": "Low",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final statuses = ["Todo", "In Progress", "Done"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: () {
              Navigator.pushNamed(context, '/create_task');
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: statuses.map((status) {
          final columnTasks =
          tasks.where((t) => t["status"] == status).toList();
          return _DashboardColumnVertical(title: status, tasks: columnTasks);
        }).toList(),
      ),
    );
  }
}

class _DashboardColumnVertical extends StatelessWidget {
  final String title;
  final List<Map<String, String>> tasks;

  const _DashboardColumnVertical({
    required this.title,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...tasks.map((t) => Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(t["title"] ?? ""),
            subtitle: Text(t["description"] ?? ""),
            trailing: Text(t["priority"] ?? ""),
            onTap: () {
              Navigator.pushNamed(context, '/task_details');
            },
          ),
        )),
        const SizedBox(height: 16),
      ],
    );
  }
}
