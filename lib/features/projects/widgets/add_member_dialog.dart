import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:go_router/go_router.dart';

// Data & Providers
import '../../../data/database/database.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/collaboration_providers.dart';
import '../../../core/constants/app_colors.dart';

/// Main screen for managing project team members.
class ProjectMembersScreen extends ConsumerWidget {
  final int projectId;

  const ProjectMembersScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(projectMembersProvider(projectId));
    
    // ✅ FORCE PREMIUM WHITE THEME CONSTANTS
    const backgroundColor = Color(0xFFF8F9FD);
    const darkText = Color(0xFF111827);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Project Team",
          style: TextStyle(fontWeight: FontWeight.w900, color: darkText),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkText),
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
          if (members.isEmpty) return _buildEmptyState();
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final memberData = members[index];
              return ProjectMemberTile(
                member: memberData.member,
                userName: memberData.user.name,
                allMembers: members,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No members found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
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

  const ProjectMemberTile({
    super.key,
    required this.member,
    required this.userName,
    required this.allMembers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
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
        title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
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
class AddMemberDialog extends ConsumerWidget {
  final int projectId;

  const AddMemberDialog({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.read(databaseProvider);
    const darkText = Color(0xFF111827);

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Add Team Member', style: TextStyle(fontWeight: FontWeight.w900, color: darkText)),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: FutureBuilder<List<User>>(
          future: _getAvailableUsers(database, projectId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data ?? [];
            if (users.isEmpty) {
              return const Center(child: Text("All registered users are already in this project.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black26)));
            }

            return ListView.separated(
              itemCount: users.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF0F4FF),
                    child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkText)),
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
    // ✅ Returns users not in current memberIds
    return (db.select(db.users)..where((t) => t.id.isNotIn(memberIds))).get();
  }

  Future<void> _addMemberToProject(BuildContext context, WidgetRef ref, User user) async {
    await ref.read(collaborationActionProvider.notifier).addMember(projectId, user.id, 'Member');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${user.name} added"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
      );
      ref.invalidate(projectMembersProvider(projectId));
      Navigator.pop(context);
    }
  }
}