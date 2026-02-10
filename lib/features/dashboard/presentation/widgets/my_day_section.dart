import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importing drift database model for backend sync
import '../../../../data/database/database.dart' as db;
// Ensure this path matches your file structure
import '../../../../core/providers/task_providers.dart';
import '../../../../data/repositories/task_repository.dart'; // ✅ Added for TaskWithAssignee type

class MyDaySection extends ConsumerWidget {
  const MyDaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 FIXED: Type changed from List<db.Task> to List<TaskWithAssignee>
    final AsyncValue<List<TaskWithAssignee>> tasksAsync = ref.watch(filteredTasksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "My Day",
          style: TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.bold, 
            color: Color(0xFF1E293B)
          ),
        ),
        const SizedBox(height: 16),
        
        tasksAsync.when(
          data: (wrappers) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            
            // ✅ Logic updated to access task inside the wrapper
            final todayTasks = wrappers.where((w) {
              if (w.task.dueDate == null) return false;
              // Today or Overdue
              return w.task.dueDate!.isBefore(today.add(const Duration(days: 1)));
            }).toList();

            if (todayTasks.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayTasks.length,
              itemBuilder: (context, index) {
                final wrapper = todayTasks[index];
                final isOverdue = wrapper.task.dueDate != null && wrapper.task.dueDate!.isBefore(today);
                
                // ✅ Pass both the task and the member name for a better UI
                return _TaskTile(
                  task: wrapper.task, 
                  assigneeName: wrapper.assignee?.name,
                  isOverdue: isOverdue,
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Error: $err", style: const TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: const Text(
        "No tasks for today. Relax! ☕",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 14),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final db.Task task;
  final String? assigneeName; // ✅ Added assignee name
  final bool isOverdue;

  const _TaskTile({required this.task, this.assigneeName, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: isOverdue ? Colors.redAccent : Colors.blueAccent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                // ✅ Show assignee name if it exists
                if (assigneeName != null)
                  Text(
                    "Assigned to: $assigneeName",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (isOverdue)
            const Text(
              "Overdue",
              style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}