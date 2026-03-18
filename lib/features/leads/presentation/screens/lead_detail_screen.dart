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

  /// ✅ DECOUPLED CONVERSION: Creates a project but removes all ID links
  Future<void> _convertToProject(BuildContext context, WidgetRef ref, Lead lead) async {
    final db = ref.read(databaseProvider);

    // 1. Prepare independent Project data (No leadReferenceId)
    final projectData = {
      'projectName': "${lead.companyName} - Project",
      'clientName': lead.contactPersonName,
      'clientEmail': lead.email ?? "",
      'status': 'In Progress',
      'description': "Project initiated from former lead: ${lead.companyName}",
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      // 2. CREATE PROJECT (Cloud & Local)
      await FirebaseFirestore.instance.collection('projects').add(projectData);
      
      await db.into(db.projects).insert(
        ProjectsCompanion.insert(
          name: "${lead.companyName} - Project",
          description: drift.Value("Client: ${lead.contactPersonName}"),
        ),
      );

      // 3. UPDATE LEAD STATUS (To ensure it's removed from 'Active' leads)
      // We mark it as 'Converted' so it doesn't stay in the 'Closed' list
      await (db.update(db.leads)..where((l) => l.id.equals(lead.id))).write(
        const LeadsCompanion(status: drift.Value("Converted")),
      );

      // Update Firestore Lead status as well
      final leadQuery = await FirebaseFirestore.instance
          .collection('leads')
          .where('mobile', isEqualTo: lead.mobile)
          .get();
      
      for (var doc in leadQuery.docs) {
        await doc.reference.update({'status': 'Converted'});
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Success: Data migrated to Project Module."),
            backgroundColor: Colors.deepPurple,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Exit detail view after conversion
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

        // Only show conversion button if lead is specifically 'Closed'
        final bool isClosed = (lead.status ?? "").toLowerCase() == "closed";

        return Scaffold(
          backgroundColor: isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, db, lead, isDark),
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
                        _buildHeader(lead),
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
                        if (isClosed) ...[
                          const SizedBox(height: 20),
                          _buildConvertButton(context, ref, lead),
                        ],
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

  // --- UI HELPER COMPONENTS ---

  Widget _buildAppBar(BuildContext context, AppDatabase db, Lead lead, bool isDark) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: const Center(child: Icon(Icons.business_center_rounded, size: 50, color: Colors.white24)),
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditLeadScreen(lead: lead)))),
        IconButton(icon: const Icon(Icons.delete_sweep_rounded), onPressed: () => _confirmDelete(context, db, lead)),
      ],
    );
  }

  Widget _buildHeader(Lead lead) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(lead.companyName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
        _StatusChip(status: lead.status ?? "unknown"),
      ],
    );
  }

  Widget _buildInfoSection(bool isDark, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(children: tiles),
        ),
        const SizedBox(height: 24),
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
        label: const Text("FINALIZE & START PROJECT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppDatabase db, Lead lead) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Archive Lead?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("DELETE", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await (db.delete(db.leads)..where((l) => l.id.equals(lead.id))).go();
      Navigator.pop(context);
    }
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _InfoTile(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
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
    if (status.toLowerCase() == "hot") color = Colors.redAccent;
    if (status.toLowerCase() == "closed") color = Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}