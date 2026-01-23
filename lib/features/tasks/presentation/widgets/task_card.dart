import 'package:flutter/material.dart';
// 1. REMOVE the old manual task_model import
// import '../../../../data/models/task_model.dart'; 

// 2. ADD the database import instead (this matches TaskListScreen)
import '../../../../data/database/database.dart'; 
import '../../../../data/models/enums.dart';

class TaskCard extends StatelessWidget {
  // Now 'Task' refers to the one in database.dart
  final Task task; 
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleDone,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Logic remains exactly the same
    final isDone = task.status == TaskStatus.done.name;
    const primaryText = Color(0xFF111827);

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Added margin for spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onToggleDone,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isDone ? Colors.green : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone ? Colors.green : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDone ? Colors.grey : primaryText,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      // Drift uses null for empty descriptions, so we check for both
                      if (task.description != null && task.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            task.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, 
                    color: Colors.red.withOpacity(0.7), size: 22),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}