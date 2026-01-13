import 'package:flutter/material.dart';

class TaskListScreen extends StatelessWidget {
  final String searchQuery;

  const TaskListScreen({super.key, this.searchQuery = ""});

  final List<String> allTasks = const [
    "Buy groceries",
    "Complete project",
    "Call mom",
    "Read book",
    "Workout",
    "Check emails",
  ];

  @override
  Widget build(BuildContext context) {
    final filteredTasks = allTasks
        .where((task) => task.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    if (filteredTasks.isEmpty) {
      return const Center(child: Text("No tasks found"));
    }

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(filteredTasks[index]),
          leading: const Icon(Icons.check_box_outline_blank),
        );
      },
    );
  }
}
