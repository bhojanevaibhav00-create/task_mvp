import 'package:flutter/material.dart';
import '../../../../data/models/task_model.dart';
import 'task_tile.dart';

class BoardColumn extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  const BoardColumn({super.key, required this.title, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title (${tasks.length})", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...tasks.map((t) => TaskTile(task: t)).toList(),
        ],
      ),
    );
  }
}
