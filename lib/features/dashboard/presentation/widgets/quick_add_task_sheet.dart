import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/task_providers.dart';
import '../../../../core/providers/collaboration_providers.dart';
import '../../../../data/database/database.dart';

class QuickAddTaskSheet extends ConsumerStatefulWidget {
  const QuickAddTaskSheet({super.key});

  @override
  ConsumerState<QuickAddTaskSheet> createState() =>
      _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState extends ConsumerState<QuickAddTaskSheet> {
  final _titleController = TextEditingController();
  int? selectedProjectId;

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(allProjectsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Task title',
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          /// PROJECT PICKER
          projectsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (projects) {
              if (projects.isEmpty) {
                return const Text('No projects available');
              }

              return Wrap(
                spacing: 8,
                children: projects.map((p) {
                  final selected = selectedProjectId == p.id;
                  return ChoiceChip(
                    label: Text(p.name),
                    selected: selected,
                    selectedColor:
                    AppColors.primary.withOpacity(0.2),
                    onSelected: (_) {
                      setState(() {
                        selectedProjectId = p.id;
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 20),

          /// ACTIONS
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () {
                  if (_titleController.text.trim().isEmpty) return;

                  ref.read(tasksProvider.notifier).addTask(
                    _titleController.text.trim(),
                    '',
                    projectId: selectedProjectId,
                  );

                  Navigator.pop(context);
                },
                child: const Text(
                  'Add Task',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}