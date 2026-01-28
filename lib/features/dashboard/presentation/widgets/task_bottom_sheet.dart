import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/constants/app_colors.dart';
import '../../../../data/database/database.dart' as db;
import '../../../../core/providers/task_providers.dart';

class TaskBottomSheet extends ConsumerStatefulWidget {
  final List<db.Project> projects;

  const TaskBottomSheet({super.key, required this.projects});

  @override
  ConsumerState<TaskBottomSheet> createState() => _TaskBottomSheetState();
}

class _TaskBottomSheetState extends ConsumerState<TaskBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  db.Project? selectedProject;
  int selectedPriority = 1; // 1: Low, 2: Medium, 3: High

  @override
  void initState() {
    super.initState();
    if (widget.projects.isNotEmpty) selectedProject = widget.projects.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "New Task",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 20),
          
          // Task Title Field
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "What needs to be done?",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 20),

          // Project Selection Dropdown
          const _Label(text: "Project"),
          const SizedBox(height: 8),
          _buildDropdownContainer(
            child: DropdownButton<db.Project>(
              value: selectedProject,
              isExpanded: true,
              underline: const SizedBox(),
              items: widget.projects
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: (v) => setState(() => selectedProject = v),
            ),
          ),
          const SizedBox(height: 20),

          // Priority Selection
          const _Label(text: "Priority"),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _priorityChip(1, "Low", Colors.green),
              _priorityChip(2, "Medium", Colors.orange),
              _priorityChip(3, "High", Colors.red),
            ],
          ),
          const SizedBox(height: 32),

          // Add Task Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _saveTask,
              child: const Text("Create Task", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _saveTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty || selectedProject == null) return;

    // 🚀 Calling the TasksNotifier to save in Drift Database
    ref.read(tasksProvider.notifier).addTask(
          title,
          "", // Default empty description
          priority: selectedPriority,
          projectId: selectedProject!.id,
          dueDate: DateTime.now(), // Defaulting to today for My Day
        );

    Navigator.pop(context);
  }

  Widget _priorityChip(int val, String label, Color color) {
    final isSelected = selectedPriority == val;
    return GestureDetector(
      onTap: () => setState(() => selectedPriority = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? color : Colors.grey, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey));
  }
}

// Global function to call the sheet
void openTaskBottomSheet({
  required BuildContext context,
  required List<db.Project> projects,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TaskBottomSheet(projects: projects),
  );
}