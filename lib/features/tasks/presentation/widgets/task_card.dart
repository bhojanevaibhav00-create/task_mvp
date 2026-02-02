import 'package:flutter/material.dart';
import '../../../../data/database/database.dart'; 
import '../../../../data/models/enums.dart';
import '../../../../core/constants/app_colors.dart';

class TaskCard extends StatelessWidget {
  final Task task; 
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final VoidCallback? onDelete;
  final String? assigneeName; 

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleDone,
    this.onDelete,
    this.assigneeName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = task.status == TaskStatus.done.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // ✅ PREMIUM WHITE THEME: Using solid white for light mode
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16), // Softer corners
        boxShadow: [
          BoxShadow(
            // ✅ SUBTLE SHADOW: Avoids "dirty" look on white backgrounds
            color: isDark ? Colors.black45 : Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 1. STATUS TOGGLE (Consistent Checkbox)
                GestureDetector(
                  onTap: onToggleDone,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDone ? Colors.green : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone 
                            ? Colors.green 
                            : (isDark ? Colors.white24 : Colors.grey.shade300),
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),

                // 2. TASK INFO (High Contrast Text)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          // ✅ FIX: High-contrast text for white theme visibility
                          color: isDone 
                              ? Colors.grey.shade400 
                              : (isDark ? Colors.white : const Color(0xFF1F2937)),
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.description != null && task.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            task.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 3. ASSIGNEE AVATAR
                if (task.assigneeId != null)
                  _buildAssigneeAvatar(isDark),

                // 4. DELETE ACTION (Subtle delete icon)
                if (onDelete != null)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.delete_sweep_outlined, 
                      color: Colors.red.withOpacity(isDark ? 0.4 : 0.6), 
                      size: 20
                    ),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssigneeAvatar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Tooltip(
        message: "Assigned to ${assigneeName ?? 'Team Member'}",
        child: CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: assigneeName != null && assigneeName!.isNotEmpty
              ? Text(
                  assigneeName![0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9, 
                    fontWeight: FontWeight.bold, 
                    color: AppColors.primary
                  ),
                )
              : const Icon(Icons.person, size: 12, color: AppColors.primary),
        ),
      ),
    );
  }
}