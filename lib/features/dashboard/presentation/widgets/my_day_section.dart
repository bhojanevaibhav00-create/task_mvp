import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importing drift database model for backend sync
import '../../../../data/database/database.dart' as db;
// Ensure this path matches your file structure
import '../../../../core/providers/task_providers.dart';

class MyDaySection extends ConsumerWidget {
  const MyDaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 FIXED: Changed 'tasksProvider' to 'filteredTasksProvider'
    // 'filteredTasksProvider' is a StreamProvider which returns AsyncValue
    final AsyncValue<List<db.Task>> tasksAsync = ref.watch(filteredTasksProvider);

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
        
        // 🚀 Now .when() will work perfectly because filteredTasksProvider is a Stream
        tasksAsync.when(
          data: (tasks) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            
            // Filter: Task is due today or before today (overdue)
            final todayTasks = tasks.where((task) {
              if (task.dueDate == null) return false;
              return task.dueDate!.isBefore(today.add(const Duration(days: 1)));
            }).toList();

            if (todayTasks.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayTasks.length,
              itemBuilder: (context, index) {
                final task = todayTasks[index];
                final isOverdue = task.dueDate != null && task.dueDate!.isBefore(today);
                
                return _TaskTile(task: task, isOverdue: isOverdue);
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
  final bool isOverdue;

  const _TaskTile({required this.task, required this.isOverdue});

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
            child: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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