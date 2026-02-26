import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/collaboration_providers.dart';

class AddMemberDialog extends ConsumerStatefulWidget {
  final int projectId;

  const AddMemberDialog({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<AddMemberDialog> createState() =>
      _AddMemberDialogState();
}

class _AddMemberDialogState
    extends ConsumerState<AddMemberDialog> {

  String selectedRole = 'Member';

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final darkText = isDark
        ? Colors.white
        : const Color(0xFF111827);

    return AlertDialog(
      backgroundColor:
          isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28)),
      title: Text(
        'Add Team Member',
        style: TextStyle(
            fontWeight: FontWeight.w900,
            color: darkText),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedRole,
              dropdownColor:
                  isDark ? AppColors.cardDark : Colors.white,
              decoration: InputDecoration(
                labelText: "Assign Role",
                labelStyle: TextStyle(
                  color: isDark
                      ? Colors.white38
                      : Colors.black38,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white10
                    : const Color(0xFFF8F9FD),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'Owner',
                    child: Text('Owner')),
                DropdownMenuItem(
                    value: 'Admin',
                    child: Text('Admin')),
                DropdownMenuItem(
                    value: 'Member',
                    child: Text('Member')),
              ],
              onChanged: (v) =>
                  setState(() => selectedRole = v!),
            ),
            const SizedBox(height: 20),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<_UserItem>>(
                future: _getAvailableUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child:
                            CircularProgressIndicator());
                  }

                  final users = snapshot.data ?? [];

                  if (users.isEmpty) {
                    return const Center(
                      child: Text(
                        "No more users available to add.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.black26),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder:
                        (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final user = users[index];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary
                                  .withOpacity(0.1),
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0]
                                    .toUpperCase()
                                : "?",
                            style: const TextStyle(
                              color:
                                  AppColors.primary,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 14,
                            color: darkText,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons
                                .add_circle_outline_rounded,
                            color: Colors.green,
                          ),
                          onPressed: () =>
                              _addMemberToProject(
                                  user),
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
          onPressed: () =>
              Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// =====================================================
  /// GET USERS NOT ALREADY IN PROJECT
  /// =====================================================
  Future<List<_UserItem>> _getAvailableUsers() async {
    final projectRef = FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId.toString());

    final projectDoc = await projectRef.get();

    final data = projectDoc.data() ?? {};

    final members =
        List<String>.from(data['members'] ?? []);

    final usersSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .get();

    final List<_UserItem> result = [];

    for (final doc in usersSnapshot.docs) {
      final uid = doc.id;

      // Skip if already member
      if (members.contains(uid)) continue;

      final userData = doc.data();

      result.add(
        _UserItem(
          uid: uid,
          name: userData['name'] ?? '',
        ),
      );
    }

    return result;
  }

  /// =====================================================
  /// ADD MEMBER
  /// =====================================================
  Future<void> _addMemberToProject(
      _UserItem user) async {
    try {
      final firebaseUser =
          FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) return;

      final projectRef =
          FirebaseFirestore.instance
              .collection('projects')
              .doc(widget.projectId.toString());

      final projectDoc =
          await projectRef.get();

      final data = projectDoc.data() ?? {};

      final roles =
          Map<String, dynamic>.from(
              data['roles'] ?? {});

      final members =
          List<String>.from(
              data['members'] ?? []);

      final currentUserRole =
          roles[firebaseUser.uid];

      // 🔐 Permission check
      if (currentUserRole != 'owner' &&
          currentUserRole != 'admin') {
        throw Exception(
            "Only Owner or Admin can add members");
      }

      if (members.contains(user.uid)) {
        throw Exception(
            "User already added");
      }

      // 🔥 Update Firestore safely
      await projectRef.set({
        'members':
            FieldValue.arrayUnion([user.uid]),
        'roles.${user.uid}':
            selectedRole.toLowerCase(),
      }, SetOptions(merge: true));

      ref.invalidate(
          projectMembersProvider(widget.projectId));

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
                "${user.name} added as $selectedRole"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
                e.toString().replaceAll(
                    "Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Internal Firestore User Model
class _UserItem {
  final String uid;
  final String name;

  _UserItem({
    required this.uid,
    required this.name,
  });
}