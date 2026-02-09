import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/collaboration_providers.dart';
import '../../../../core/constants/app_colors.dart';

class AddMemberDialog extends ConsumerStatefulWidget {
  final int projectId;
  const AddMemberDialog({super.key, required this.projectId});

  @override
  ConsumerState<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<AddMemberDialog> {
  int? selectedUserId;
  String selectedRole = 'Member';

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(projectMembersProvider(widget.projectId));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Member'),
      content: membersAsync.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text(e.toString()),
        data: (members) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                hint: const Text('Select User'),
                items: members
                    .map(
                      (m) => DropdownMenuItem(
                    value: m.user.id,
                    child: Text(m.user.name),
                  ),
                )
                    .toList(),
                onChanged: (v) => setState(() => selectedUserId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'Owner', child: Text('Owner')),
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'Member', child: Text('Member')),
                ],
                onChanged: (v) => setState(() => selectedRole = v!),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          onPressed: selectedUserId == null
              ? null
              : () async {
            await ref
                .read(collaborationActionProvider.notifier)
                .addMember(
              projectId: widget.projectId,
              userId: selectedUserId!,
              role: selectedRole,
            );

            ref.invalidate(projectMembersProvider(widget.projectId));

            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
