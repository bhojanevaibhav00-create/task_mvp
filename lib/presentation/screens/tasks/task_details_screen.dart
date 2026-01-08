import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy task data
    final task = {
      "title": "Design Login Screen",
      "description": "Design login and signup pages",
      "remarks": "Needs approval from UI team",
      "status": "In Progress",
      "priority": "High",
      "due": "20 Jan",
    };

    return Scaffold(
      appBar: AppBar(title: const Text("Task Details")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task["title"] ?? "", style: AppTextStyles.heading),
            const SizedBox(height: 8),
            Text("Description: ${task["description"]}", style: AppTextStyles.body),
            const SizedBox(height: 8),
            Text("Remarks: ${task["remarks"]}", style: AppTextStyles.body),
            const SizedBox(height: 8),
            Text("Status: ${task["status"]}", style: AppTextStyles.body),
            const SizedBox(height: 8),
            Text("Priority: ${task["priority"]}", style: AppTextStyles.body),
            const SizedBox(height: 8),
            Text("Due Date: ${task["due"]}", style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
