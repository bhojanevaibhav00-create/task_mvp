import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

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

  /// Convert Lead → Project
 Future<void> _convertToProject(
    BuildContext context, WidgetRef ref, Lead lead) async {

  final db = ref.read(databaseProvider);

  final projectData = {
    'projectName': "${lead.companyName} - Project",
    'clientName': lead.contactPersonName,
    'clientEmail': lead.email ?? "",
    'status': 'In Progress',
    'leadReferenceId': lead.id,
    'createdAt': FieldValue.serverTimestamp(),
  };

  try {

    /// Firebase
    await FirebaseFirestore.instance
        .collection('projects')
        .add(projectData);

    /// Drift
    await db.into(db.projects).insert(
      ProjectsCompanion.insert(
        name: "${lead.companyName} - Project",
        description: drift.Value("Client: ${lead.contactPersonName}"),
      ),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lead converted to Project successfully"),
          backgroundColor: Colors.green,
        ),
      );
    }

  } catch (e) {

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Conversion Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

  }

  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<Lead?>(
      stream: (db.select(db.leads)..where((l) => l.id.equals(leadId)))
          .watchSingleOrNull(),
      builder: (context, snapshot) {
        final lead = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || lead == null) {
          return const Scaffold(
            body: Center(child: Text("Lead not found")),
          );
        }

        final bool isClosed = (lead.status ?? "").toLowerCase() == "closed";

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),

          /// APPBAR
          appBar: AppBar(
            title: const Text(
              "Lead Details",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: isDark ? AppColors.cardDark : Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditLeadScreen(lead: lead),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent),
                onPressed: () => _confirmDelete(context, db, lead),
              ),
            ],
          ),

          /// BODY
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Company Name
                Text(
                  lead.companyName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                _StatusChip(status: lead.status ?? "unknown"),

                const Divider(height: 40),

                /// Contact
                _buildSectionTitle("Contact Information"),

                _InfoTile(
                    "Contact Person", lead.contactPersonName, Icons.person),

                _InfoTile("Mobile", lead.mobile, Icons.phone_android),

                _InfoTile(
                  "Email",
                  lead.email ?? "No Email Provided",
                  Icons.email_outlined,
                ),

                const SizedBox(height: 10),

                /// Deal
                _buildSectionTitle("Deal Details"),

                _InfoTile(
                  "Product Pitched",
                  lead.productPitched ?? "Not specified",
                  Icons.shopping_bag_outlined,
                ),

                _InfoTile(
                  "Discussion / Remarks",
                  lead.discussion ?? "No remarks",
                  Icons.notes,
                ),

                const SizedBox(height: 10),

                /// Schedule
                _buildSectionTitle("Schedule"),

                _InfoTile(
                  "Follow-up Date",
                  lead.followUpDate != null
                      ? "${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year}"
                      : "Not Scheduled",
                  Icons.calendar_today_outlined,
                ),

                _InfoTile(
                  "Follow-up Time",
                  lead.followUpTime ?? "Not Set",
                  Icons.access_time,
                ),

                const SizedBox(height: 40),

                /// Convert Button
                if (isClosed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _convertToProject(context, ref, lead),
                      icon: const Icon(Icons.rocket_launch,
                          color: Colors.white),
                      label: const Text(
                        "CONVERT TO PROJECT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.primary.withOpacity(0.8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppDatabase db, Lead lead) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Lead?"),
        content: const Text(
            "This will remove the lead from local storage and Firebase."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "DELETE",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('leads')
            .where('mobile', isEqualTo: lead.mobile)
            .get();

        for (var doc in query.docs) {
          await doc.reference.delete();
        }

        await (db.delete(db.leads)..where((l) => l.id.equals(lead.id))).go();

        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error deleting: $e")));
      }
    }
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 20,
              color: isDark ? Colors.white38 : Colors.black38),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white54 : Colors.black45)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: color,
          fontSize: 12,
        ),
      ),
    );
  }
}