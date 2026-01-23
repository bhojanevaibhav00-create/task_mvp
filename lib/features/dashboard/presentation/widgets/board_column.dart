import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/task_model.dart'; // 👈 Ensure this is your manual model
import 'task_tile.dart';

class BoardColumn extends StatelessWidget {
  final String title;
  final List<Task> tasks; // This refers to the Task in task_model.dart

  const BoardColumn({super.key, required this.title, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEDF0).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Expanded ensures the list is scrollable within the column
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskTile(task: tasks[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}