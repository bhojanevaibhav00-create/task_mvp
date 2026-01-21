import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/enums.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/board_column.dart';
import 'package:task_mvp/core/constants/app_colors.dart';


class BoardScreen extends StatelessWidget {
  final Project project;
  const BoardScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    // Group tasks by status
    final todoTasks =
    project.tasks.where((t) => t.status == TaskStatus.todo).toList();
    final inProgressTasks =
    project.tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    final doneTasks =
    project.tasks.where((t) => t.status == TaskStatus.done).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        flexibleSpace:
        Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BoardColumn(title: "To Do", tasks: todoTasks),
            const SizedBox(width: 12),
            BoardColumn(title: "In Progress", tasks: inProgressTasks),
            const SizedBox(width: 12),
            BoardColumn(title: "Done", tasks: doneTasks),
          ],
        ),
      ),
    );
  }
}
