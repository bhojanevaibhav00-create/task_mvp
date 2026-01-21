import 'package:flutter/material.dart';

class ProjectSkeleton extends StatelessWidget {
  const ProjectSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 16, width: 150, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Container(height: 12, width: 100, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}
