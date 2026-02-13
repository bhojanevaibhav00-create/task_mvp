import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/collaboration_providers.dart';
import '../../../data/database/database.dart';
import '../widgets/add_member_dialog.dart';

class ProjectMembersScreen extends ConsumerWidget {
  final int projectId;

  const ProjectMembersScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(projectMembersProvider(projectId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),

      /// ✅ CONSISTENT GRADIENT APPBAR (Matches Dashboard)
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Project Members",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 4,
        onPressed: () => _showAddMemberDialog(context),
        child: const Icon(Icons.person_add_alt_1_rounded,
            color: Colors.white),
      ),

      body: membersAsync.when(
        data: (List<MemberWithUser> membersList) {
          if (membersList.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            itemCount: membersList.length,
            itemBuilder: (context, index) {
              final item = membersList[index];
              return _buildMemberTile(
                  context, ref, item, membersList, isDark);
            },
          );
        },
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text("Error: $e")),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          AddMemberDialog(projectId: projectId),
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

    final isOwner =
        member.role.toLowerCase() == 'owner';
    final ownerCount = allMembers
        .where((m) =>
    m.member.role.toLowerCase() ==
        'owner')
        .length;
    final isLastOwner =
        isOwner && ownerCount <= 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding:
      const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color:
        isDark ? AppColors.cardDark : Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(
            vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor:
          AppColors.primary.withOpacity(0.1),
          child: Text(
            user.name.isNotEmpty
                ? user.name[0].toUpperCase()
                : "?",
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: isDark
                ? Colors.white
                : Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding:
          const EdgeInsets.only(top: 6),
          child: _buildRoleChip(
              member.role, isOwner, isDark),
        ),
        trailing: IconButton(
          splashRadius: 22,
          icon: Icon(
            Icons.person_remove_rounded,
            size: 20,
            color: isLastOwner
                ? Colors.grey.shade400
                : Colors.redAccent,
          ),
          onPressed: () {
            if (isLastOwner) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                      "At least 1 Owner required"),
                  backgroundColor:
                  Colors.orange,
                ),
              );
            } else {
              _confirmRemoval(
                  context, ref, item, allMembers);
            }
          },
        ),
      ),
    );
  }

  Widget _buildRoleChip(
      String role, bool isOwner, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOwner
            ? Colors.orange.withOpacity(0.15)
            : AppColors.primary
            .withOpacity(0.15),
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isOwner
              ? Colors.orange.shade800
              : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 70,
              color: isDark
                  ? Colors.white
                  .withOpacity(0.15)
                  : Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              "No Members Yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w900,
                color: isDark
                    ? Colors.white38
                    : Colors.black45,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap + button to invite members",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? Colors.white24
                    : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoval(
      BuildContext context,
      WidgetRef ref,
      MemberWithUser item,
      List<MemberWithUser> allMembers,
      ) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
        isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20)),
        title: const Text(
          "Remove Member?",
          style:
          TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
            "Remove ${item.user.name} from this project?"),
        actions: [
          TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref
                  .read(collaborationActionProvider
                  .notifier)
                  .removeMember(
                projectId: projectId,
                userId:
                item.member.userId,
                allMembers: allMembers,
              );

              ref.invalidate(
                  projectMembersProvider(
                      projectId));

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }
}