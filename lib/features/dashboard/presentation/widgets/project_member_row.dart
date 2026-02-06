import 'package:flutter/material.dart';
import 'package:task_mvp/features/projects/presentation/screens/project_member_ui.dart';
import '../../../../core/constants/app_colors.dart';

class MemberRow extends StatelessWidget {
  final ProjectMemberUI member;
  final VoidCallback? onRemove;

  const MemberRow({
    super.key,
    required this.member,
    this.onRemove,
  });

  bool get isOwner => member.role.name.toLowerCase() == 'owner';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          /// Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              member.user.name.isNotEmpty
                  ? member.user.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          /// Name + Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.user.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                _RoleChip(role: member.role.name),
              ],
            ),
          ),

          /// Remove (UI only)
          if (onRemove != null)
            IconButton(
              icon: Icon(
                Icons.close,
                color: isOwner ? Colors.grey : Colors.redAccent,
              ),
              onPressed: isOwner ? null : onRemove,
            ),
        ],
      ),
    );
  }
}

/// ================= ROLE CHIP =================
class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final isOwner = role.toLowerCase() == 'owner';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOwner
            ? Colors.orange.withOpacity(0.12)
            : Colors.blue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isOwner ? Colors.orange.shade800 : Colors.blue.shade800,
        ),
      ),
    );
  }
}