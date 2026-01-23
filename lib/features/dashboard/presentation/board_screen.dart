import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/models/task_model.dart'; // Ensure this is the ONLY Task import
import '../../../../data/models/enums.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/board_column.dart';

class BoardScreen extends StatelessWidget {
  final Project project;
  const BoardScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    // 1. Force the list to be recognized as List<Task>
    final List<Task> allTasks = project.tasks;

    // 2. Filter with explicit type casting to List<Task>
    final List<Task> todoTasks = allTasks
        .where((t) => t.status == TaskStatus.todo)
        .toList();
        
    final List<Task> inProgressTasks = allTasks
        .where((t) => t.status == TaskStatus.inProgress)
        .toList();
        
    final List<Task> doneTasks = allTasks
        .where((t) => t.status == TaskStatus.done)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Using the helper ensures types are passed correctly
            _buildColumnWrapper("To Do", todoTasks, AppColors.primary),
            const SizedBox(width: 16),
            _buildColumnWrapper("In Progress", inProgressTasks, Colors.orange),
            const SizedBox(width: 16),
            _buildColumnWrapper("Done", doneTasks, Colors.green),
          ],
        ),
      ),
    );
  }

  // 3. This helper ensures the widget receives a strict List<Task>
  Widget _buildColumnWrapper(String title, List<Task> tasks, Color accentColor) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFEBEDF0).withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text("${tasks.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ),
          Flexible(
            child: BoardColumn(
              title: title, 
              tasks: tasks, // THE ERROR SHOULD NOW BE GONE
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}