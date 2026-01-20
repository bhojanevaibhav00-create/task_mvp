import 'package:flutter/material.dart';
import 'package:task_mvp/data/models/project_model.dart';
import 'package:task_mvp/data/models/task_model.dart';
import 'package:task_mvp/data/models/enums.dart';
import 'package:task_mvp/core/constants/app_colors.dart';

/// Opens a bottom sheet to quickly add a task
void openTaskBottomSheet({
  required BuildContext context,
  required List<Project> projects,
  required VoidCallback onUpdate,
}) {
  final controller = TextEditingController();
  Priority priority = Priority.medium;
  Project selectedProject = projects.first;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Add Task",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "Task title"),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<Project>(
                    value: selectedProject,
                    isExpanded: true,
                    items: projects
                        .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name),
                    ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) selectedProject = v;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<Priority>(
                    value: priority,
                    isExpanded: true,
                    items: Priority.values
                        .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name),
                    ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) priority = v;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  selectedProject.tasks.add(Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: controller.text,
                    priority: priority,
                  ));
                  onUpdate();
                  Navigator.pop(context);
                }
              },
              child: const Text("Add Task"),
            ),
          ],
        ),
      ),
    ),
  );
}
