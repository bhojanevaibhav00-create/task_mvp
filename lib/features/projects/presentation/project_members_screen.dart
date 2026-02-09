import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/collaboration_providers.dart';

class ProjectMembersScreen extends ConsumerWidget {
  final int projectId;

  const ProjectMembersScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final membersAsync = ref.watch(projectMembersProvider(projectId));

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,

      // ===== HEADER =====
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        title: const Text(
          'Project Members',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      body: membersAsync.when(
        loading: () =>
        const Center(child: CircularProgressIndicator()),

        error: (e, _) => Center(
          child: Text('Error: $e'),
        ),

        data: (members) {
          if (members.isEmpty) {
            return const _EmptyMembersState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final member = members[index];

              // ✅ FIRST MEMBER = OWNER (SAFE LOGIC)
              final isOwner = index == 0;

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color:
                  isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    // ===== AVATAR =====
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                      AppColors.primary.withOpacity(0.12),
                      child: Text(
                        member.user.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // ===== NAME + ROLE =====
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOwner
                                  ? Colors.orange.withOpacity(0.15)
                                  : Colors.blue.withOpacity(0.15),
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOwner ? 'OWNER' : 'MEMBER',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isOwner
                                    ? Colors.orange
                                    : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ===== REMOVE (UI ONLY FOR NOW) =====
                    if (!isOwner)
                      IconButton(
                        icon: const Icon(Icons.person_remove,
                            color: Colors.red),
                        onPressed: () {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Remove member – logic pending'),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ===== EMPTY STATE =====
class _EmptyMembersState extends StatelessWidget {
  const _EmptyMembersState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.group_outlined,
              size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No members yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}