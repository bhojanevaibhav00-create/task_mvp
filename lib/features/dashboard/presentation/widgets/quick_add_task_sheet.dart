import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/task_providers.dart';
import '../../../../core/providers/project_providers.dart';
import '../../../../data/database/database.dart';
import '../../../../data/models/enums.dart';
import '../../../../core/providers/database_provider.dart';

class QuickAddTaskSheet extends ConsumerStatefulWidget {
  const QuickAddTaskSheet({super.key});

  @override
  ConsumerState<QuickAddTaskSheet> createState() => _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState extends ConsumerState<QuickAddTaskSheet> {
  final _controller = TextEditingController();
  int _selectedPriority = 2; // Default: Medium (2)
  DateTime? _selectedDate;
  int? _selectedProjectId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Colors.white;
    const inputBg = Color(0xFFF8F9FD);
    const primaryText = Color(0xFF1A1C1E);
    final projectsAsync = ref.watch(allProjectsProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quick Add Task",
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.w900, 
                color: primaryText,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // --- Title Input ---
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: primaryText, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: "What needs to be done?",
                hintStyle: const TextStyle(color: Colors.black26),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
            const SizedBox(height: 24),

            // --- Project Picker (Vaishnavi's P0) ---
            _buildProjectLabel(),
            const SizedBox(height: 12),
            projectsAsync.when(
              data: (projects) => _buildProjectChips(projects),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            
            // --- Date & Priority Row ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildDateSelector()),
                const SizedBox(width: 16),
                Expanded(child: _buildPrioritySelector()),
              ],
            ),
            const SizedBox(height: 32),
            
            // --- Action Button ---
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: () => _handleAddTask(ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text(
                  "Create Task", 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectLabel() => const Text(
        "SELECT PROJECT", 
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 1.2),
      );

  Widget _buildProjectChips(List<Project> projects) {
    if (projects.isEmpty) return const Text("No projects available", style: TextStyle(color: Colors.black26));
    return Wrap(
      spacing: 8,
      children: projects.map((p) {
        final selected = _selectedProjectId == p.id;
        return ChoiceChip(
          label: Text(p.name),
          selected: selected,
          onSelected: (val) => setState(() => _selectedProjectId = val ? p.id : null),
          selectedColor: AppColors.primary.withOpacity(0.15),
          labelStyle: TextStyle(
            color: selected ? AppColors.primary : Colors.black45,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("DUE DATE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(_selectedDate == null ? "Set Date" : "${_selectedDate!.day}/${_selectedDate!.month}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("PRIORITY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        DropdownButton<int>(
          value: _selectedPriority,
          isExpanded: true,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 1, child: Text("Low")),
            DropdownMenuItem(value: 2, child: Text("Med")),
            DropdownMenuItem(value: 3, child: Text("High")),
          ],
          onChanged: (val) => setState(() => _selectedPriority = val!),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _handleAddTask(WidgetRef ref) async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    
    final db = ref.read(databaseProvider);
    await db.into(db.tasks).insert(TasksCompanion.insert(
      title: title,
      priority: drift.Value(_selectedPriority),
      dueDate: drift.Value(_selectedDate),
      projectId: drift.Value(_selectedProjectId),
      status: drift.Value(TaskStatus.todo.name),
      createdAt: drift.Value(DateTime.now()),
    ));

    ref.invalidate(tasksProvider);
    if (mounted) Navigator.pop(context);
  }
}