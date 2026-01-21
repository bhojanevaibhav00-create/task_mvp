import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/enums.dart';

class TaskBottomSheet extends StatefulWidget {
  final List<Project> projects;
  final VoidCallback onUpdate;

  const TaskBottomSheet({super.key, required this.projects, required this.onUpdate});

  @override
  State<TaskBottomSheet> createState() => _TaskBottomSheetState();
}

class _TaskBottomSheetState extends State<TaskBottomSheet> {
  String title = "";
  Project? selectedProject;
  Priority priority = Priority.medium;
  bool important = false;

  @override
  void initState() {
    super.initState();
    if (widget.projects.isNotEmpty) selectedProject = widget.projects.first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            onChanged: (v) => setState(() => title = v),
            decoration: const InputDecoration(hintText: "Task Title"),
          ),
          const SizedBox(height: 12),
          DropdownButton<Project>(
            value: selectedProject,
            isExpanded: true,
            items: widget.projects
                .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                .toList(),
            onChanged: (v) => setState(() => selectedProject = v),
          ),
          const SizedBox(height: 12),
          DropdownButton<Priority>(
            value: priority,
            isExpanded: true,
            items: Priority.values
                .map((p) => DropdownMenuItem(
              value: p,
              child: Text(p.name.toUpperCase()),
            ))
                .toList(),
            onChanged: (v) => setState(() => priority = v!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text("Important"),
              Switch(
                value: important,
                onChanged: (v) => setState(() => important = v),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              backgroundColor: AppColors.primary,
            ),
            onPressed: () {
              if (title.isEmpty || selectedProject == null) return;
              selectedProject!.tasks.add(Task(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  priority: priority,
                  status: TaskStatus.todo,
                  important: important,
                  tags: []));
              widget.onUpdate();
              Navigator.pop(context);
            },
            child: const Text("Add Task"),
          ),
        ],
      ),
    );
  }
}

void openTaskBottomSheet({
  required BuildContext context,
  required List<Project> projects,
  required VoidCallback onUpdate,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TaskBottomSheet(projects: projects, onUpdate: onUpdate),
  );
}
