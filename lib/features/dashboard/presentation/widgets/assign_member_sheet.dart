import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/providers/task_providers.dart';
import '../../../../core/providers/collaboration_providers.dart';
import '../../../../data/database/database.dart';

class AssignMemberSheet extends ConsumerWidget {
  final int? projectId;
  final int? taskId;

  const AssignMemberSheet({
    super.key,
    this.projectId,
    this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 Watching the provider for the list of all system users
    final usersAsync = ref.watch(allUsersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            taskId != null ? "Assign to Task" : "Add to Project",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (users) {
              if (users.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text("No users found in the system."),
                );
              }

              return Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(user.name[0].toUpperCase()),
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(user.email),
                      onTap: () async {
                        // 1️⃣ CASE: ASSIGN TO TASK
                        if (taskId != null) {
                          final tasks = ref.read(tasksProvider);
                          final task = tasks.firstWhere((t) => t.id == taskId);

                          await ref.read(tasksProvider.notifier).updateTask(
                                task.copyWith(
                                  assigneeId: drift.Value(user.id),
                                ),
                              );
                        }

                        // 2️⃣ CASE: ASSIGN TO PROJECT
                        if (projectId != null) {
                          // ✅ FIXED: Using collaborationActionProvider with Named Parameters
                          await ref.read(collaborationActionProvider.notifier).addMember(
                                projectId: projectId!,
                                userId: user.id.toString(),
                                role: 'Member', // Default role
                              );
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}