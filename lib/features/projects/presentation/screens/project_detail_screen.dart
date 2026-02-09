import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/task_providers.dart';
import '../../../../core/providers/collaboration_providers.dart';

import 'package:task_mvp/features/dashboard/presentation/widgets/assignee_chip.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/assign_member_sheet.dart';
import '../project_members_screen.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final int projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tasks = ref.watch(filteredTasksProvider).value ?? [];
    final membersAsync = ref.watch(projectMembersProvider(projectId));

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,

      // ================= PREMIUM HEADER =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        title: const Text(
          'Project Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProjectMembersScreen(projectId: projectId),
                ),
              );
            },
          ),
        ],
      ),

      // ================= BODY =================
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- MEMBERS ----------
          const Text(
            'Members',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          membersAsync.when(
            loading: () =>
            const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (members) {
              if (members.isEmpty) {
                return const Text('No members added');
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: members.map((m) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        m.user.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    label: Text(m.user.name),
                    backgroundColor:
                    AppColors.primary.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 32),

          // ---------- TASKS ----------
          const Text(
            'Tasks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          if (tasks.where((t) => t.projectId == projectId).isEmpty)
            const Text(
              'No tasks in this project',
              style: TextStyle(color: Colors.grey),
            ),

          ...tasks
              .where((t) => t.projectId == projectId)
              .map((task) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                title: Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: task.description == null
                    ? null
                    : Text(
                  task.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: AssigneeChip(
                  name: task.assigneeId == null
                      ? null
                      : 'User ${task.assigneeId}',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) =>
                          AssignMemberSheet(taskId: task.id),
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ),

      // ================= ADD MEMBER FAB =================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Add Member',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) =>
                AssignMemberSheet(projectId: projectId),
          );
        },
      ),
    );
  }
}