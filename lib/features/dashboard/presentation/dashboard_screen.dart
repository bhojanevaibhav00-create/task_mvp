import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/providers/task_providers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/enums.dart';
import '../../../core/providers/notification_providers.dart';
import '../../notifications/presentation/notification_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);

    final completedTasks =
        tasks.where((t) => t.status == TaskStatus.done.name).length;
    final pendingTasks =
        tasks.where((t) => t.status != TaskStatus.done.name).length;

    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.red,
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // ================= SUMMARY =================
            Row(
              children: [
                _statCard('Total', tasks.length, Colors.blue),
                const SizedBox(width: 12),
                _statCard('Pending', pendingTasks, Colors.orange),
                const SizedBox(width: 12),
                _statCard('Completed', completedTasks, Colors.green),
              ],
            ),

            const SizedBox(height: 30),

            // ================= QUICK ACTIONS =================
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppButton(
                  text: 'View Tasks',
                  onPressed: () => context.push(AppRoutes.tasks),
                ),
                AppButton(
                  text: 'Add Task',
                  onPressed: () => context.push(AppRoutes.tasks),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ================= RECENT TASKS =================
            const Text(
              'Recent Tasks',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Text('No tasks yet. Add your first task!'),
                    )
                  : ListView.builder(
                      itemCount: tasks.length.clamp(0, 5),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Card(
                          child: ListTile(
                            title: Text(task.title),
                            subtitle: Text('Status: ${task.status}'),
                            trailing: Icon(
                              task.status == TaskStatus.done.name
                                  ? Icons.check_circle
                                  : Icons.pending,
                              color: task.status == TaskStatus.done.name
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            onTap: () => context.push(AppRoutes.tasks),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, int value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
