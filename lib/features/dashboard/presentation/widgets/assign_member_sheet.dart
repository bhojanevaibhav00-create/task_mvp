import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/providers/task_providers.dart';
import '../../../../core/providers/collaboration_providers.dart';

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
    final usersAsync = ref.watch(allUsersProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: usersAsync.when(
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (users) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: users.map((user) {
              return ListTile(
                title: Text(user.name),
                onTap: () async {
                  /// ✅ ASSIGN TO TASK
                  if (taskId != null) {
                    final task = ref
                        .read(tasksProvider)
                        .firstWhere((t) => t.id == taskId);

                    await ref
                        .read(tasksProvider.notifier)
                        .updateTask(
                      task.copyWith(
                        assigneeId: drift.Value(user.id),
                      ),
                    );
                  }

                  /// ✅ ASSIGN TO PROJECT
                  if (projectId != null) {
                    await ref
                        .read(collaborationRepositoryProvider)
                        .addMember(
                      projectId!,
                      user.id,
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}