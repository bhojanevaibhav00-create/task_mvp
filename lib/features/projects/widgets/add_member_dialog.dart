import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../data/database/database.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/providers/collaboration_providers.dart';
import '../../../core/constants/app_colors.dart';

/// Screen displaying the list of project members and the option to add more.
class ProjectMembersScreen extends ConsumerWidget {
  final int projectId;

  const ProjectMembersScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch project members to keep the UI in sync
    final membersAsync = ref.watch(projectMembersProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Team"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AddMemberDialog(projectId: projectId),
            ),
          ),
        ],
      ),
      body: membersAsync.when(
        data: (members) => ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final memberData = members[index];
            return ProjectMemberTile(
              member: memberData.member,
              userName: memberData.user.name,
              allMembers: members, // Needed for owner safety check
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }
}

/// A tile for each member that handles the removal logic and safety alerts.
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
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Text(userName[0].toUpperCase()),
      ),
      title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Role: ${member.role}"),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
        onPressed: () => _handleRemove(context, ref),
      ),
    );
  }

  /// Handles the removal of a member with role safety checks.
  Future<void> _handleRemove(BuildContext context, WidgetRef ref) async {
    try {
      // 🛡️ ROLE SAFETY: Calling the removal logic in the provider
      await ref.read(collaborationActionProvider.notifier).removeMember(
            member.projectId,
            member.userId,
            allMembers,
          );

      // Refresh the UI list
      ref.invalidate(projectMembersProvider(member.projectId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Member removed successfully")),
        );
      }
    } catch (e) {
      // ⚠️ ERROR HANDLING: Show snackbar if trying to remove the last owner
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

/// Dialog updated with English comments and duplicate prevention logic.
class AddMemberDialog extends ConsumerWidget {
  final int projectId;

  const AddMemberDialog({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.read(databaseProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Team Member', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: FutureBuilder<List<User>>(
          // 🚀 PREVENT DUPLICATES: Only fetch users not already in the project
          future: _getAvailableUsers(database, projectId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data ?? [];

            if (users.isEmpty) {
              return const Center(
                child: Text("No new users found", style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: Colors.blue)),
                  ),
                  title: Text(user.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
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
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  /// Logic to filter out users who are already project members.
  Future<List<User>> _getAvailableUsers(AppDatabase db, int pId) async {
    final members = await (db.select(db.projectMembers)..where((t) => t.projectId.equals(pId))).get();
    final memberIds = members.map((m) => m.userId).toList();

    return (db.select(db.users)..where((t) => t.id.isNotIn(memberIds))).get();
  }

  /// Adds member and triggers UI refresh and success message.
  Future<void> _addMemberToProject(BuildContext context, WidgetRef ref, User user) async {
    await ref.read(collaborationActionProvider.notifier).addMember(
          projectId,
          user.id,
          'Member',
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${user.name} added to project"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
      ref.invalidate(projectMembersProvider(projectId));
    }
  }
}