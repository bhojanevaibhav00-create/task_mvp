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
    // ✅ FORCED WHITE THEME: Ignoring system isDark to prevent "dark leakage"
    const bool isDarkTheme = false; 
    final isDone = task.status == TaskStatus.done.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // ✅ PREMIUM WHITE: Using pure white for the card
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [
          BoxShadow(
            // ✅ SUBTLE SHADOW: Depth without the "dirty" look
            color: Colors.black.withOpacity(0.04),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // 1. STATUS TOGGLE
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
                        color: isDone ? Colors.green : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),

                // 2. TASK INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          // ✅ HIGH CONTRAST: Slate dark for maximum readability
                          color: isDone 
                              ? Colors.grey.shade400 
                              : const Color(0xFF111827), 
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 3. ASSIGNEE AVATAR (Collaboration Indicator)
                if (task.assigneeId != null)
                  _buildAssigneeAvatar(),

                // 4. DELETE ACTION
                if (onDelete != null)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.delete_outline_rounded, 
                      color: Colors.red.withOpacity(0.5), 
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

  Widget _buildAssigneeAvatar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: assigneeName != null && assigneeName!.isNotEmpty
            ? Text(
                assigneeName![0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.w900, 
                  color: AppColors.primary
                ),
              )
            : const Icon(Icons.person, size: 12, color: AppColors.primary),
      ),
    );
  }
}