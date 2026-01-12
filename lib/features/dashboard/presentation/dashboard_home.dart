import 'package:flutter/material.dart';
import '../../tasks/data/task_repository.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/summary_card.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/section.dart';
import 'package:task_mvp/features/dashboard/presentation/widgets/task_tile.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final today = TaskRepository.todayTasks();
    final overdue = TaskRepository.overdueTasks();
    final upcoming = TaskRepository.upcomingTasks();
    final recent = TaskRepository.recentTasks();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF0EA5E9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Good Morning 👋",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Let’s be productive today",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SummaryCard(
                  title: "Today",
                  count: today.length.toString(),
                  icon: Icons.today,
                  color: const Color(0xFF0EA5E9),
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: "Overdue",
                  count: overdue.length.toString(),
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: "Upcoming",
                  count: upcoming.length.toString(),
                  icon: Icons.schedule,
                  color: const Color(0xFF22C55E),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // My Day
          Section(title: "My Day"),
          ...overdue.map(
            (t) => TaskTile(
              title: t.title,
              status: "Overdue",
              statusColor: const Color(0xFFEF4444),
            ),
          ),
          ...today.map(
            (t) => TaskTile(
              title: t.title,
              status: "Today",
              statusColor: const Color(0xFF0EA5E9),
            ),
          ),

          const SizedBox(height: 32),

          // Recent
          Section(title: "Recent Activity"),
          ...recent.map(
            (t) => TaskTile(
              title: t.title,
              status: t.status.name.toUpperCase(),
              statusColor: const Color(0xFF6366F1),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
