import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

// Core Constants & Providers
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/collaboration_providers.dart';

// Data Layer
import '../../../data/database/database.dart';
import '../widgets/add_member_dialog.dart';

class ProjectMembersScreen extends ConsumerWidget {
  final int projectId;
  const ProjectMembersScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 Watching the provider for real-time member updates
    final membersAsync = ref.watch(projectMembersProvider(projectId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const darkText = Color(0xFF111827); // High contrast slate dark

    return Scaffold(
      // ✅ FORCED PREMIUM WHITE THEME
      backgroundColor: isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Project Members",
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            color: isDark ? Colors.white : darkText
          ),
        ),
        backgroundColor: isDark ? AppColors.scaffoldDark : Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddMemberDialog(context),
        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
      ),

      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "Error loading members\n$e", 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
        data: (List<MemberWithUser> members) {
          if (members.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: members.length,
            itemBuilder: (context, index) =>
                _buildMemberTile(context, ref, members[index], members, isDark),
          );
        },
      ),
    );
  }

  // ================= MEMBER TILE =================

  Widget _buildMemberTile(
    BuildContext context,
    WidgetRef ref,
    MemberWithUser item,
    List<MemberWithUser> allMembers,
    bool isDark,
  ) {
    final user = item.user;
    final role = item.member.role.toLowerCase();

    // Logic for Role Safety: Ensure at least one owner remains
    final ownerCount = allMembers.where((m) => m.member.role.toLowerCase() == 'owner').length;
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Text(
            user.name[0].toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: TextStyle(
            fontWeight: FontWeight.w700, 
            fontSize: 16, 
            color: isDark ? Colors.white : const Color(0xFF111827)
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [_buildRoleChip(role)],
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            isLastOwner ? Icons.lock_outline_rounded : Icons.person_remove_rounded,
            color: isLastOwner ? Colors.grey.shade300 : Colors.redAccent.withOpacity(0.7),
          ),
          onPressed: () {
            if (isLastOwner) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("At least 1 Owner required for safety"),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              _confirmRemoval(context, ref, item, allMembers);
            }
          },
        ),
      ),
    );
  }

  // ================= ROLE CHIP =================

  Widget _buildRoleChip(String role) {
    final isOwner = role == 'owner';
    final color = isOwner ? Colors.orange : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color.shade800,
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
          Icon(Icons.group_outlined, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text(
            "Team is Empty",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Invite members to collaborate.", 
            style: TextStyle(color: Colors.black26)
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

  void _confirmRemoval(
    BuildContext context,
    WidgetRef ref,
    MemberWithUser item,
    List<MemberWithUser> allMembers,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Remove Member?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to remove ${item.user.name} from this project?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, 
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }
}