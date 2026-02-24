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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectMembersScreen extends ConsumerWidget {
  final int projectId;

  const ProjectMembersScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 Watching the provider for real-time member updates
    final membersAsync = ref.watch(projectMembersProvider(projectId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final darkText = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      // ✅ ADAPTIVE PREMIUM THEME
      backgroundColor: isDark
          ? AppColors.scaffoldDark
          : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Project Members",
          style: TextStyle(fontWeight: FontWeight.w900, color: darkText),
        ),
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkText),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 70,
        ), // Lifted to avoid overlap with Save button
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: () => _showAddMemberDialog(context),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          membersAsync.when(
            data: (List<MemberWithUser> membersList) {
              if (membersList.isEmpty) {
                return _buildEmptyState(isDark);
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  100,
                ), // Bottom padding for button
                itemCount: membersList.length,
                itemBuilder: (context, index) {
                  final item = membersList[index];
                  return _buildMemberTile(
                    context,
                    ref,
                    item,
                    membersList,
                    isDark,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Connection Error: $e",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // ✅ FIXED BOTTOM SAVE BUTTON
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD))
                        .withOpacity(0),
                    isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
                  ],
                ),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddMemberDialog(projectId: projectId),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    WidgetRef ref,
    MemberWithUser item,
    List<MemberWithUser> allMembers,
    bool isDark,
  ) {
    final member = item.member;
    final user = item.user;

    final isOwner = member.role.toLowerCase() == 'owner';
    final ownerCount = allMembers
        .where((m) => m.member.role.toLowerCase() == 'owner')
        .length;
    final isLastOwner = isOwner && ownerCount <= 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(children: [_buildRoleChip(member.role, isOwner)]),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.person_remove_rounded,
            color: isLastOwner
                ? Colors.grey.shade400
                : Colors.redAccent.withOpacity(0.7),
          ),
          onPressed: () {
            if (isLastOwner) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("At least 1 Owner required for safety"),
                  backgroundColor: Colors.orange,
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

  Widget _buildRoleChip(String role, bool isOwner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOwner
            ? Colors.orange.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: isOwner ? Colors.orange.shade800 : Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 80,
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            "Team is Empty",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Invite members to collaborate.",
            style: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
          ),
        ],
      ),
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
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Remove Member?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to remove ${item.user.name} from this project?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final firebaseUser = FirebaseAuth.instance.currentUser;

                // ============================
                // 1️⃣ REMOVE FROM DRIFT
                // ============================
                await ref
                    .read(collaborationActionProvider.notifier)
                    .removeMember(
                      projectId: projectId,
                      userId: item.member.userId,
                      allMembers: allMembers,
                    );

               // ============================
// 2️⃣ REMOVE FROM FIRESTORE (CORRECT PATH)
// ============================
await FirebaseFirestore.instance
    .collection('projects')
    .doc(projectId.toString())
    .collection('members')
    .doc(item.member.userId.toString())
    .delete();


                ref.invalidate(projectMembersProvider(projectId));

                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to remove member: $e")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }
}
