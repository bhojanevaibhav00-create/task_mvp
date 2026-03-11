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

  const LeadDetailScreen({super.key, required this.leadId});

  Future<void> _convertToProject(BuildContext context, WidgetRef ref, Lead lead) async {
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
      await FirebaseFirestore.instance.collection('projects').add(projectData);
      await db.into(db.projects).insert(
        ProjectsCompanion.insert(
          name: "${lead.companyName} - Project",
          description: drift.Value("Client: ${lead.contactPersonName}"),
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lead converted successfully!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<Lead?>(
      stream: (db.select(db.leads)..where((l) => l.id.equals(leadId))).watchSingleOrNull(),
      builder: (context, snapshot) {
        final lead = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || lead == null) {
          return const Scaffold(body: Center(child: Text("Lead not found")));
        }

        final bool isClosed = (lead.status ?? "").toLowerCase() == "closed";

        return Scaffold(
          backgroundColor: isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ================= PREMIUM HEADER =================
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                stretch: true,
                backgroundColor: isDark ? AppColors.cardDark : AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Container(
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.business_rounded, size: 35, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditLeadScreen(lead: lead))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                    onPressed: () => _confirmDelete(context, db, lead),
                  ),
                ],
              ),

              // ================= PROFILE CONTENT =================
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(lead.companyName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1)),
                            ),
                            _StatusChip(status: lead.status ?? "unknown"),
                          ],
                        ),
                        const SizedBox(height: 30),
                        
                        _buildInfoSection(isDark, "CONTACT PERSON", [
                          _InfoTile("Full Name", lead.contactPersonName, Icons.person_rounded),
                          _InfoTile("Mobile", lead.mobile, Icons.phone_iphone_rounded),
                          _InfoTile("Email", lead.email ?? "No Email", Icons.alternate_email_rounded),
                        ]),

                        _buildInfoSection(isDark, "DEAL INTELLIGENCE", [
                          _InfoTile("Product Pitched", lead.productPitched ?? "General", Icons.auto_awesome_rounded),
                          _InfoTile("Remarks", lead.discussion ?? "None", Icons.chat_bubble_outline_rounded),
                        ]),

                        _buildInfoSection(isDark, "NEXT FOLLOW-UP", [
                          _InfoTile(
                            "Schedule", 
                            lead.followUpDate != null 
                                ? "${lead.followUpDate!.day}/${lead.followUpDate!.month} at ${lead.followUpTime ?? 'TBD'}"
                                : "No follow-up set", 
                            Icons.calendar_today_rounded
                          ),
                        ]),

                        const SizedBox(height: 40),

                        if (isClosed)
                          _buildConvertButton(context, ref, lead),
                        
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(bool isDark, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.5)),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildConvertButton(BuildContext context, WidgetRef ref, Lead lead) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.indigoAccent]),
        boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _convertToProject(context, ref, lead),
        icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white),
        label: const Text("CONVERT TO PROJECT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppDatabase db, Lead lead) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Archive Lead?"),
        content: const Text("Are you sure you want to remove this lead? This action is permanent."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("DELETE", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final query = await FirebaseFirestore.instance.collection('leads').where('mobile', isEqualTo: lead.mobile).get();
      for (var doc in query.docs) { await doc.reference.delete(); }
      await (db.delete(db.leads)..where((l) => l.id.equals(lead.id))).go();
      if (context.mounted) Navigator.pop(context);
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
    Color color = AppColors.primary;
    switch (status.toLowerCase()) {
      case "hot": color = Colors.redAccent; break;
      case "warm": color = Colors.orangeAccent; break;
      case "cold": color = Colors.blueAccent; break;
      case "closed": color = Colors.green; break;
      case "lost": color = Colors.grey; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 11)),
    );
  }
}