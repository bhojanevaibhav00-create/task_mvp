import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_mvp/core/constants/app_colors.dart';
import 'package:task_mvp/core/providers/collaboration_providers.dart'; 

// ✅ Ensure this import points to the file where your ProjectMembersScreen is
// If you named the file project_members_screen.dart, use that path here:
import 'package:task_mvp/features/projects/widgets/add_member_dialog.dart'; 

class ProjectDetailScreen extends ConsumerWidget {
  final int projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watching the global provider we moved to collaboration_providers
    final projectsAsync = ref.watch(allProjectsProvider);
    
    return projectsAsync.when(
      data: (projects) {
        // Find the specific project from the list
        final project = projects.firstWhere((p) => p.id == projectId);
        
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: AppBar(
            title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.group_add_rounded),
                tooltip: "Manage Team",
                onPressed: () {
                  // ✅ FIXED: Changed AddMemberScreen to ProjectMembersScreen 
                  // to match the class name in your other file.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProjectMembersScreen(projectId: projectId),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(project.description ?? "No description provided"),
                const SizedBox(height: 24),
                const Text(
                  "Project Tasks",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Expanded(
                  child: Center(
                    child: Text("Tasks for this project will appear here"),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              context.push('/tasks/create?projectId=$projectId');
            },
            label: const Text("Add Project Task"),
            icon: const Icon(Icons.add),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Error: $e"))),
    );
  }

  Widget _buildInfoCard(String desc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Description", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }
}