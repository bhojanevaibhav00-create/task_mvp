import 'package:flutter/material.dart';
import '../../widgets/cards/project_card.dart';
import '../../theme/app_text_styles.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Projects")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your Projects", style: AppTextStyles.heading),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  ProjectCard(title: "Mobile App", taskCount: 12),
                  ProjectCard(title: "Website Redesign", taskCount: 8),
                  ProjectCard(title: "Marketing Plan", taskCount: 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
