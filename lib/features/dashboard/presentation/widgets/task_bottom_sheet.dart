import 'package:flutter/material.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/enums.dart';

void openTaskBottomSheet({
  required BuildContext context,
  required List<Project> projects,
  required VoidCallback onUpdate,
}) {
  final TextEditingController titleController = TextEditingController();
  Project? selectedProject;
  Priority selectedPriority = Priority.medium;
  DateTime? dueDate;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Task Title"),
              ),
              const SizedBox(height: 12),
              DropdownButton<Project>(
                hint: const Text("Select Project"),
                value: selectedProject,
                isExpanded: true,
                items: projects
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => selectedProject = v,
              ),
              const SizedBox(height: 12),
              DropdownButton<Priority>(
                value: selectedPriority,
                isExpanded: true,
                items: Priority.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => selectedPriority = v!,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isEmpty || selectedProject == null) return;
                  selectedProject!.tasks.add(Task(
                    id: DateTime.now().toString(),
                    title: titleController.text,
                    priority: selectedPriority,
                  ));
                  onUpdate();
                  Navigator.pop(context);
                },
                child: const Text("Add Task"),
              ),
            ],
          ),
        ),
      );
    },
  );
}
