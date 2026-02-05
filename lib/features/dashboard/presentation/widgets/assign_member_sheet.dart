import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/collaboration_providers.dart';
import '../../../../core/constants/app_colors.dart';

class AssignMemberSheet extends ConsumerWidget {
  final int projectId;

  const AssignMemberSheet({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(projectMembersProvider(projectId));

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Assign Member',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),

            membersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Text('Error: $e'),
              data: (members) {
                if (members.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No members available'),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: members.length + 1,
                  separatorBuilder: (_, __) =>
                  const Divider(height: 1),
                  itemBuilder: (context, index) {
                    // 🔹 UNASSIGN OPTION
                    if (index == 0) {
                      return ListTile(
                        leading: const Icon(Icons.close, color: Colors.red),
                        title: const Text(
                          'Unassign',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context, null);
                        },
                      );
                    }

                    final item = members[index - 1];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                        AppColors.primary.withOpacity(0.1),
                        child: Text(
                          item.user.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(item.user.name),
                      subtitle: Text(item.member.role),
                      onTap: () {
                        Navigator.pop(context, item);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}