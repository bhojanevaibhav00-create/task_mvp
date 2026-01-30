import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/database/database.dart' as db;
import '../../../../core/providers/collaboration_providers.dart';
import '../../../../core/constants/app_colors.dart';

class AnimatedProjectCard extends ConsumerWidget {
  final db.Project project;
  final VoidCallback onTap;

  const AnimatedProjectCard({
    required this.project, 
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetching project members dynamically from backend
    final membersAsync = ref.watch(projectMembersProvider(project.id));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Displaying team member initials as avatars
                membersAsync.when(
                  data: (members) => SizedBox(
                    height: 30,
                    width: 80,
                    child: Stack(
                      children: List.generate(
                        members.length > 3 ? 3 : members.length,
                        (index) => Positioned(
                          left: index * 15.0,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.primary.withOpacity(0.2),
                              child: Text(
                                members[index].user.name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  loading: () => const SizedBox(width: 40, child: LinearProgressIndicator()),
                  error: (_, __) => const Icon(Icons.group, size: 20),
                ),
                const Spacer(),
                const Text("Progress: 65%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            // Premium Linear Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                value: 0.65,
                minHeight: 6,
                backgroundColor: Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}