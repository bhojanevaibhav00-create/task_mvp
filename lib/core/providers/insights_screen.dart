import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/analytics_provider.dart';
import '../../data/models/analytics_models.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final membersAsync = ref.watch(
      memberStatsProvider(null),
    ); // null = All Projects

    return Scaffold(
      appBar: AppBar(title: const Text('Productivity Insights')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(memberStatsProvider(null));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Key Metrics Cards
              statsAsync.when(
                data: (stats) => _buildSummaryCards(context, stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
              ),

              const SizedBox(height: 24),

              // 2. Weekly Progress Section
              const Text(
                'Weekly Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              statsAsync.when(
                data: (stats) => _buildWeeklyProgress(context, stats),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // 3. Team Performance Section
              const Text(
                'Team Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              membersAsync.when(
                data: (members) => _buildMemberList(members),
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (err, _) => Text('Could not load team stats: $err'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, DashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Overdue',
            value: stats.overdueCount.toString(),
            color: Colors.redAccent,
            icon: Icons.warning_amber_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Completion Rate',
            value: '${(stats.completionRate * 100).toStringAsFixed(1)}%',
            color: Colors.green,
            icon: Icons.check_circle_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyProgress(BuildContext context, DashboardStats stats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _ProgressRow(
              label: 'Tasks Created',
              value: stats.createdThisWeek,
              color: Colors.blue,
              total:
                  stats.createdThisWeek +
                  stats.completedThisWeek, // Relative scale
            ),
            const SizedBox(height: 16),
            _ProgressRow(
              label: 'Tasks Completed',
              value: stats.completedThisWeek,
              color: Colors.green,
              total: stats.createdThisWeek + stats.completedThisWeek,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberList(List<MemberStats> members) {
    if (members.isEmpty) {
      return const Text('No active members found.');
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: members.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final m = members[index];
          return ListTile(
            leading: CircleAvatar(child: Text(m.userName[0])),
            title: Text(m.userName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinearProgressIndicator(value: m.progress, minHeight: 6),
                const SizedBox(height: 4),
                Text(
                  '${m.completedTasks} / ${m.assignedTasks} tasks completed',
                ),
              ],
            ),
            trailing: Text(
              '${(m.progress * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = total == 0 ? 0 : value / total;
    // Cap visual percentage at 1.0 but keep logic sound
    final double visualProgress = percentage > 1.0 ? 1.0 : percentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: total == 0 ? 0 : visualProgress,
          color: color,
          backgroundColor: color.withOpacity(0.2),
        ),
      ],
    );
  }
}
