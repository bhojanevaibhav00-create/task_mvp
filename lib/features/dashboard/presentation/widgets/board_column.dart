import 'package:flutter/material.dart';
import '../../../../data/database/database.dart' as db;
import 'task_tile.dart';

class BoardColumn extends StatelessWidget {
  final String title;
  final List<db.Task> tasks;

  const BoardColumn({
    super.key,
    required this.title,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// COLUMN TITLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          /// TASK LIST
          Expanded(
            child: tasks.isEmpty
                ? const Center(
              child: Text(
                'No tasks',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.separated(
              itemCount: tasks.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = tasks[index];

                return TaskTile(
                  task: task,
                  onTap: () {
                    // UI-only navigation for now
                    // You can hook TaskDetailScreen later
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}