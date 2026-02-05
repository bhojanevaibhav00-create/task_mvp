import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/database.dart' as db;
import '../../../core/providers/collaboration_providers.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/add_member_dialog.dart';

class ProjectMembersScreen extends ConsumerWidget {
  final int projectId;
  const ProjectMembersScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(projectMembersProvider(projectId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),

      appBar: AppBar(
        title: const Text(
          "Project Members",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.scaffoldDark : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),

      /// ✅ ADD MEMBER FAB (correct)
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddMemberDialog(context),
        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
      ),

      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "Error loading members\n$e",
              textAlign: TextAlign.center,
            ),
          ),
        ),

        data: (List<MemberWithUser> members) {
          if (members.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: members.length,
            itemBuilder: (_, i) =>
                _memberTile(context, ref, members[i], members, isDark),
          );
        },
      ),
    );
  }

  // ================= MEMBER TILE =================

  Widget _memberTile(
      BuildContext context,
      WidgetRef ref,
      MemberWithUser item,
      List<MemberWithUser> allMembers,
      bool isDark,
      ) {
    final user = item.user;
    final role = item.member.role.toLowerCase();

    final ownerCount =
        allMembers.where((m) => m.member.role == 'owner').length;
    final isLastOwner = role == 'owner' && ownerCount == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),

        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Text(
            user.name[0].toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),

        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: _roleChip(role),
        ),

        /// ✅ REMOVE MEMBER (SAFE)
        trailing: IconButton(
          icon: Icon(
            isLastOwner ? Icons.lock : Icons.person_remove_rounded,
            color: isLastOwner ? Colors.grey : Colors.redAccent,
          ),
          onPressed: isLastOwner
              ? () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("At least one Owner is required"),
                backgroundColor: Colors.orange,
              ),
            );
          }
              : () => _confirmRemove(context, ref, item, allMembers),
        ),
      ),
    );
  }

  // ================= ROLE CHIP =================

  Widget _roleChip(String role) {
    final isOwner = role == 'owner';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOwner
            ? Colors.orange.withOpacity(0.15)
            : Colors.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isOwner ? Colors.orange.shade800 : Colors.blue.shade800,
        ),
      ),
    );
  }

  // ================= EMPTY STATE =================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "No Members Yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add members to start collaboration",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ================= DIALOGS =================

  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddMemberDialog(projectId: projectId),
    );
  }

  void _confirmRemove(
      BuildContext context,
      WidgetRef ref,
      MemberWithUser item,
      List<MemberWithUser> allMembers,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text("Remove Member"),
        content: Text(
          "Are you sure you want to remove ${item.user.name} from this project?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              await ref
                  .read(collaborationActionProvider.notifier)
                  .removeMember(
                projectId,
                item.member.userId,
                allMembers,
              );
              ref.invalidate(projectMembersProvider(projectId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }
}