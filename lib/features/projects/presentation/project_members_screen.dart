import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/database.dart' as db;
import '../../../core/providers/collaboration_providers.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/add_member_dialog.dart'; // 🚀 खात्री करा की ही फाईल तुम्ही तयार केली आहे

class ProjectMembersScreen extends ConsumerWidget {
  final int projectId;
  const ProjectMembersScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(projectMembersProvider(projectId));
    const darkText = Color(0xFF111827);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Project Members",
          style: TextStyle(fontWeight: FontWeight.bold, color: darkText),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkText),
      ),
      // 🚀 पायरी १: Add Member Flow साठी Floating Action Button ॲड केले
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddMemberDialog(context),
        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
      ),
      body: membersAsync.when(
        data: (List<MemberWithUser> membersList) {
          debugPrint("Project ID $projectId: Found ${membersList.length} members");

          if (membersList.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: membersList.length,
            itemBuilder: (context, index) {
              final item = membersList[index];
              return _buildMemberTile(context, ref, item, membersList);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text("Database Error: $e", textAlign: TextAlign.center),
          ),
        ),
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
  ) {
    final member = item.member;
    final user = item.user;

    final isOwner = member.role.toLowerCase() == 'owner';
    final ownerCount = allMembers.where((m) => m.member.role.toLowerCase() == 'owner').length;
    final isLastOwner = isOwner && ownerCount <= 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
            style: const TextStyle(
              color: AppColors.primary, 
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _buildRoleChip(member.role, isOwner),
            ],
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.person_remove_rounded,
            // 🚀 पायरी २: Last-owner protection व्हिज्युअली दाखवण्यासाठी रंग बदलला
            color: isLastOwner ? Colors.grey.shade300 : Colors.redAccent,
          ),
          onPressed: () {
            if (isLastOwner) {
              // 🚀 पायरी ३: प्रोटेक्शन मेसेज दाखवणे
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("At least 1 Owner required"),
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
        color: isOwner ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isOwner ? Colors.orange.shade800 : Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "No Members Found", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            "Project ID: $projectId has no assigned users.", 
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _confirmRemoval(BuildContext context, WidgetRef ref, MemberWithUser item, List<MemberWithUser> allMembers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Remove Member?"),
        content: Text("Are you sure you want to remove ${item.user.name} from this project?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(collaborationActionProvider.notifier).removeMember(
                projectId, 
                item.member.userId, 
                allMembers,
              );
              ref.invalidate(projectMembersProvider(projectId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Remove", 
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}