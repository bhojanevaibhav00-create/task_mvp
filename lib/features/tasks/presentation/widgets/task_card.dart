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
    // 💡 DETERMINING THEME STATE
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = task.status == TaskStatus.done.name;

    // 💡 DYNAMIC COLORS
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: borderColor),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 1. PRIORITY INDICATOR STRIPE
              _buildPriorityStripe(task.priority),

              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      child: Row(
                        children: [
                          // 2. STATUS TOGGLE
                          _buildCheckbox(isDone, isDark),
                          const SizedBox(width: 16),

                          // 3. TASK INFO
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDone 
                                        ? (isDark ? Colors.white24 : Colors.black26)
                                        : titleColor, 
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (task.dueDate != null) ...[
                                      Icon(
                                        Icons.calendar_today_rounded, 
                                        size: 10, 
                                        color: isDone 
                                            ? (isDark ? Colors.white12 : Colors.black12) 
                                            : AppColors.primary.withOpacity(0.5)
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}",
                                        style: TextStyle(
                                          fontSize: 11, 
                                          color: isDone ? (isDark ? Colors.white10 : Colors.black12) : subtitleColor, 
                                          fontWeight: FontWeight.w600
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    
                                    if (task.description != null && task.description!.isNotEmpty)
                                      Expanded(
                                        child: Text(
                                          task.description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDone ? (isDark ? Colors.white10 : Colors.black12) : subtitleColor,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 4. ASSIGNEE AVATAR
                          if (task.assigneeId != null)
                            _buildAssigneeAvatar(isDark),

                          // 5. DELETE ACTION
                          if (onDelete != null)
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.delete_sweep_outlined, 
                                color: Colors.red.withOpacity(0.4), 
                                size: 20
                              ),
                              onPressed: onDelete,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityStripe(int? priority) {
    Color stripeColor;
    switch (priority) {
      case 1: stripeColor = Colors.green.shade300; break;
      case 3: stripeColor = Colors.red.shade400; break;
      default: stripeColor = Colors.orange.shade300;
    }
    return Container(
      width: 6,
      color: stripeColor.withOpacity(0.8),
    );
  }

  Widget _buildCheckbox(bool isDone, bool isDark) {
    return GestureDetector(
      onTap: onToggleDone,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isDone ? Colors.green : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDone ? Colors.green : (isDark ? Colors.white24 : Colors.grey.shade300),
            width: 2,
          ),
        ),
        child: isDone
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildAssigneeAvatar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Tooltip(
        message: assigneeName ?? "Assigned Member",
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
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
            if (assigneeName != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  assigneeName!.split(' ').first,
                  style: TextStyle(fontSize: 8, color: isDark ? Colors.white38 : Colors.black38),
                ),
              ),
          ],
        ),
      ),
    );
  }
}