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
    // ✅ REGRESSION FIX: Explicitly forcing White Theme for consistency
    final isDone = task.status == TaskStatus.done.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [
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
                          _buildCheckbox(isDone),
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
                                        ? Colors.black26 
                                        : const Color(0xFF111827), 
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    // ✅ FIXED: DUE DATE VISIBILITY (Sprint 7)
                                    if (task.dueDate != null) ...[
                                      Icon(
                                        Icons.calendar_today_rounded, 
                                        size: 10, 
                                        color: isDone ? Colors.black12 : AppColors.primary.withOpacity(0.5)
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}",
                                        style: TextStyle(
                                          fontSize: 11, 
                                          color: isDone ? Colors.black12 : Colors.black38, 
                                          fontWeight: FontWeight.w600
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    
                                    // DESCRIPTION PREVIEW
                                    if (task.description != null && task.description!.isNotEmpty)
                                      Expanded(
                                        child: Text(
                                          task.description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDone ? Colors.black12 : Colors.black38,
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
                            _buildAssigneeAvatar(),

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

  Widget _buildCheckbox(bool isDone) {
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
            color: isDone ? Colors.green : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: isDone
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
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