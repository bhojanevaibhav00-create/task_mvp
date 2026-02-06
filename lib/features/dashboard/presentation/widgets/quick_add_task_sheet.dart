import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

// Ensure these paths match your project structure exactly
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/task_providers.dart'; 
import '../../../../data/database/database.dart';
import '../../../../data/models/enums.dart';

class QuickAddTaskSheet extends ConsumerStatefulWidget {
  const QuickAddTaskSheet({super.key});

  @override
  ConsumerState<QuickAddTaskSheet> createState() => _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState extends ConsumerState<QuickAddTaskSheet> {
  final _controller = TextEditingController();
  int _selectedPriority = 2; // Default: Medium (2)
  DateTime? _selectedDate; // ✅ FIXED: Added state for Due Date

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FORCED PREMIUM WHITE THEME: Matches Dashboard style
    const backgroundColor = Colors.white;
    const inputBg = Color(0xFFF8F9FD);
    const primaryText = Color(0xFF1A1C1E);

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
            
            // ✅ Date Selection Row
            _buildDateSelector(primaryText),
            const SizedBox(height: 24),
            
            _buildPrioritySelector(primaryText),
            const SizedBox(height: 32),
            
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

  // ✅ PREMIUM DATE PICKER WIDGET
  Widget _buildDateSelector(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "DUE DATE", 
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(primary: AppColors.primary),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  _selectedDate == null 
                    ? "No date set" 
                    : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
                if (_selectedDate != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _selectedDate = null),
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PRIORITY", 
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [1, 2, 3].map((p) {
            final isSelected = _selectedPriority == p;
            final Color priorityColor;
            final String label;

            switch (p) {
              case 1: priorityColor = Colors.green; label = "Low"; break;
              case 3: priorityColor = Colors.red; label = "High"; break;
              default: priorityColor = Colors.orange; label = "Med";
            }

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (val) => setState(() => _selectedPriority = p),
                selectedColor: priorityColor.withOpacity(0.15),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? priorityColor : Colors.black.withOpacity(0.05),
                  width: 1.5,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? priorityColor : Colors.black45,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _handleAddTask(WidgetRef ref) async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    try {
      final db = ref.read(databaseProvider);
      
      await db.into(db.tasks).insert(TasksCompanion.insert(
        title: title,
        priority: drift.Value(_selectedPriority),
        dueDate: drift.Value(_selectedDate), // ✅ SAVING: Actual date now persisted
        status: drift.Value(TaskStatus.todo.name),
        createdAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
      ));

      ref.invalidate(tasksProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error adding task: $e");
    }
  }
}