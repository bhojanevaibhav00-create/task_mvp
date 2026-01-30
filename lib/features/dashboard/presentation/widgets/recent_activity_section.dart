import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 🚀 Hiding drift's Column to avoid naming conflicts with Flutter's Column widget
import 'package:drift/drift.dart' hide Column; 
import 'package:task_mvp/core/providers/task_providers.dart';
import 'package:task_mvp/data/database/database.dart' as db;

class RecentActivitySection extends ConsumerWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Accessing the database through the Riverpod provider
    final database = ref.watch(databaseProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Activity",
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        
        // 🚀 Real-time stream to watch the latest 5 activity logs
        StreamBuilder<List<db.ActivityLog>>(
          stream: (database.select(database.activityLogs)
                ..orderBy([
                  (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
                ])
                ..limit(5)) 
              .watch(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            
            final logs = snapshot.data ?? [];

            if (logs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.03)),
                ),
                child: const Text(
                  "No recent activity recorded yet.", 
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Column(
              children: logs.map((log) => _ActivityTile(
                title: log.action,
                text: log.description ?? "",
                // Formatting timestamp to HH:mm format
                time: "${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}",
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String text;
  final String time;

  const _ActivityTile({
    required this.title, 
    required this.text, 
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 10, 
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Activity Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, size: 18, color: Colors.blueAccent),
          ),
          const SizedBox(width: 12),
          // Log Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: const TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text, 
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Log Timestamp
          Text(
            time, 
            style: const TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.w600, 
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }
}