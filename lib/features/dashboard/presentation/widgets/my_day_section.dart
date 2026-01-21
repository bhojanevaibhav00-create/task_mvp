import 'package:flutter/material.dart';

class MyDaySection extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;

  const MyDaySection({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "My Day",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...tasks.map((task) {
          return _TaskTile(
            title: task['title'] ?? '',
            isOverdue: task['isOverdue'] ?? false,
          );
        }).toList(),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  final String title;
  final bool isOverdue;

  const _TaskTile({required this.title, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: isOverdue ? Colors.red : Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (isOverdue)
            const Text(
              "Overdue",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
