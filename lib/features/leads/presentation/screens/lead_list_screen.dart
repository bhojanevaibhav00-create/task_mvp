import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart'; 

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../data/database/database.dart';
import 'lead_detail_screen.dart';

// 🔹 PROVIDERS
final searchProvider = StateProvider<String>((ref) => "");

final filteredLeadsProvider = StreamProvider<List<Lead>>((ref) {
  final db = ref.watch(databaseProvider);
  final search = ref.watch(searchProvider).toLowerCase();
  
  return db.select(db.leads).watch().map((leads) {
    if (search.isEmpty) return leads;
    return leads.where((l) => 
      l.companyName.toLowerCase().contains(search) || 
      l.contactPersonName.toLowerCase().contains(search)
    ).toList();
  });
});

class LeadListScreen extends ConsumerWidget {
  const LeadListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(filteredLeadsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ================= PREMIUM SEARCH APP BAR =================
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            stretch: true,
            backgroundColor: isDark ? AppColors.cardDark : Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 65),
              title: Text(
                "Lead Directory",
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                ),
              ),
              background: Container(color: isDark ? AppColors.cardDark : Colors.white),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                child: TextField(
                  onChanged: (val) => ref.read(searchProvider.notifier).state = val,
                  decoration: InputDecoration(
                    hintText: "Search company or contact...",
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary.withOpacity(0.6)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ================= LEAD LIST CONTENT =================
          leadsAsync.when(
            data: (leads) {
              if (leads.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text("No Leads Found", style: TextStyle(color: Colors.grey))),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final lead = leads[index];
                      return _LeadCard(
                        lead: lead,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LeadDetailScreen(leadId: lead.id)),
                        ),
                      );
                    },
                    childCount: leads.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;

  const _LeadCard({required this.lead, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String followUp = lead.followUpDate != null
        ? "${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year}"
        : "Not set";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.companyName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lead.contactPersonName,
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: lead.status),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Divider(height: 1, thickness: 0.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _ContactButton(
                        icon: Icons.phone_forwarded_rounded,
                        color: Colors.green,
                        onTap: () => launchUrl(Uri.parse('tel:${lead.mobile}')),
                      ),
                      const SizedBox(width: 12),
                      _ContactButton(
                        icon: Icons.alternate_email_rounded,
                        color: Colors.blueAccent,
                        onTap: () => launchUrl(Uri.parse('mailto:${lead.email}')),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_note_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          followUp,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 18),
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
      case "hot": color = Colors.redAccent; break;
      case "warm": color = Colors.orangeAccent; break;
      case "cold": color = Colors.blueAccent; break;
      case "closed": color = Colors.green; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
      ),
    );
  }
}