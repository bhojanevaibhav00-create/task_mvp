import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:go_router/go_router.dart';

// Data & Providers
import '../../../data/database/database.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/collaboration_providers.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/constants/app_colors.dart';

/// Main screen for managing project team members.
class ProjectMembersScreen extends ConsumerWidget {
  final int projectId;

  const ProjectMembersScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(projectMembersProvider(projectId));
    
    // ✅ FORCE PREMIUM WHITE THEME CONSTANTS
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD);
    final darkText = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Project Team",
          style: TextStyle(fontWeight: FontWeight.w900, color: darkText),
        ),
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkText),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 24),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AddMemberDialog(projectId: projectId),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) return _buildEmptyState(isDark);
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final memberData = members[index];
              return ProjectMemberTile(
                member: memberData.member,
                userName: memberData.user.name,
                allMembers: members,
                isDark: isDark,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 80, color: isDark ? Colors.white10 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No members found", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.grey)),
        ],
      ),
    );
  }
}

/// A premium styled tile for team members.
class ProjectMemberTile extends ConsumerWidget {
  final ProjectMember member;
  final String userName;
  final List<MemberWithUser> allMembers;
  final bool isDark;

  const ProjectMemberTile({
    super.key,
    required this.member,
    required this.userName,
    required this.allMembers,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : "?",
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(userName, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF111827))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text("Role: ${member.role.toUpperCase()}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black38)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 22),
          onPressed: () => _handleRemove(context, ref),
        ),
      ),
    );
  }

  Future<void> _handleRemove(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(collaborationActionProvider.notifier).removeMember(
            member.projectId,
            member.userId,
            allMembers,
          );

      ref.invalidate(projectMembersProvider(member.projectId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Member removed successfully"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Dialog to invite users who are not yet in the project.
class AddMemberDialog extends ConsumerStatefulWidget {
  final int projectId;

  const AddMemberDialog({super.key, required this.projectId});

  @override
  ConsumerState<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<AddMemberDialog> {
  String selectedRole = 'Member';

  @override
  Widget build(BuildContext context) {
    final database = ref.read(databaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final darkText = isDark ? Colors.white : const Color(0xFF111827);

    return AlertDialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text('Add Team Member', style: TextStyle(fontWeight: FontWeight.w900, color: darkText)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Role Selection Dropdown from Vaishnavi's branch
            DropdownButtonFormField<String>(
              value: selectedRole,
              dropdownColor: isDark ? AppColors.cardDark : Colors.white,
              decoration: InputDecoration(
                labelText: "Assign Role",
                labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                filled: true,
                fillColor: isDark ? Colors.white10 : const Color(0xFFF8F9FD),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: const [
                DropdownMenuItem(value: 'Owner', child: Text('Owner')),
                DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                DropdownMenuItem(value: 'Member', child: Text('Member')),
              ],
              onChanged: (v) => setState(() => selectedRole = v!),
            ),
            const SizedBox(height: 20),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<User>>(
                future: _getAvailableUsers(database, widget.projectId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return const Center(child: Text("No more users available to add.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black26)));
                  }

                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(user.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkText)),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.green),
                          onPressed: () => _addMemberToProject(context, ref, user),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Future<List<User>> _getAvailableUsers(AppDatabase db, int pId) async {
    final members = await (db.select(db.projectMembers)..where((t) => t.projectId.equals(pId))).get();
    final memberIds = members.map((m) => m.userId).toList();
    return (db.select(db.users)..where((t) => t.id.isNotIn(memberIds))).get();
  }

  Future<void> _addMemberToProject(BuildContext context, WidgetRef ref, User user) async {
    await ref.read(collaborationActionProvider.notifier).addMember(widget.projectId, user.id, selectedRole);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${user.name} added as $selectedRole"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
      );
      ref.invalidate(projectMembersProvider(widget.projectId));
      Navigator.pop(context);
    }
  }
}