import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../data/database/database.dart';
import 'edit_lead_screen.dart';

class LeadDetailScreen extends ConsumerWidget {
  final int leadId;

  const LeadDetailScreen({
    super.key,
    required this.leadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<Lead?>(
      stream: (db.select(db.leads)..where((l) => l.id.equals(leadId)))
          .watchSingleOrNull(),
      builder: (context, snapshot) {
        final lead = snapshot.data;

        if (!snapshot.hasData || lead == null) {
          return const Scaffold(
            body: Center(child: Text("Lead not found")),
          );
        }

        return Scaffold(
          backgroundColor:
          isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
          appBar: AppBar(
            title: const Text("Lead Details"),
            backgroundColor:
            isDark ? AppColors.cardDark : Colors.white,
            elevation: 0,
            actions: [
              // EDIT BUTTON
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditLeadScreen(lead: lead),
                    ),
                  );
                },
              ),

              // DELETE BUTTON
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await (db.delete(db.leads)
                    ..where((l) => l.id.equals(leadId)))
                      .go();

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // COMPANY NAME
                Text(
                  lead.companyName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // STATUS CHIP
                _StatusChip(status: lead.status),

                const SizedBox(height: 30),

                _InfoTile("Contact Person", lead.contactPersonName),
                _InfoTile("Mobile", lead.mobile),
                _InfoTile("Email", lead.email ?? "-"),

                const SizedBox(height: 20),

                _InfoTile(
                  "Follow-up Date",
                  lead.followUpDate != null
                      ? "${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year}"
                      : "Not Scheduled",
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (status.toLowerCase()) {
      case "hot":
        color = Colors.red;
        break;
      case "warm":
        color = Colors.orange;
        break;
      case "cold":
        color = Colors.blue;
        break;
      case "lost":
        color = Colors.grey;
        break;
      case "closed":
        color = Colors.green;
        break;
      default:
        color = AppColors.primary;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}