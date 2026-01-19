import 'package:flutter/material.dart';
import 'package:task_mvp/data/models/project_model.dart';

class AnimatedProjectCard extends StatelessWidget {
  final Project project;
  const AnimatedProjectCard({required this.project, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(project.name),
        subtitle: Text("${project.tasks.length} tasks"),
      ),
    );
  }
}
