import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/collaboration_providers.dart';

class ProjectMemberRow extends StatelessWidget {
  final MemberWithUser member;
  final bool showRemove;

  const ProjectMemberRow({
    super.key,
    required this.member,
    this.showRemove = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = member.member.role.toLowerCase() == 'owner';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              member.user.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  member.member.role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: isOwner
                        ? Colors.orange
                        : Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          if (showRemove)
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
        ],
      ),
    );
  }
}