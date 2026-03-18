import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart'; 

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../data/database/database.dart';
import 'lead_detail_screen.dart';
import '../widgets/shimmer_loading.dart'; 

// 🔹 PROVIDERS
final searchProvider = StateProvider<String>((ref) => "");
final leadFilterProvider = StateProvider<String>((ref) => "All");

// ✅ NEW: Provider to calculate counts for the dashboard
final leadStatsProvider = StreamProvider<Map<String, int>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.leads).watch().map((leads) {
    return {
      "Total": leads.length,
      "Hot": leads.where((l) => l.status == "Hot").length,
      "Warm": leads.where((l) => l.status == "Warm").length,
      "Cold": leads.where((l) => l.status == "Cold").length,
    };
  });
});

final filteredLeadsProvider = StreamProvider<List<Lead>>((ref) {
  final db = ref.watch(databaseProvider);
  final search = ref.watch(searchProvider).toLowerCase();
  final filter = ref.watch(leadFilterProvider);
  
  return db.select(db.leads).watch().map((leads) {
    var list = leads;
    if (filter != "All") list = list.where((l) => l.status == filter).toList();
    if (search.isNotEmpty) {
      list = list.where((l) => 
        l.companyName.toLowerCase().contains(search) || 
        l.contactPersonName.toLowerCase().contains(search)
      ).toList();
    }
    return list;
  });
});

class LeadListScreen extends ConsumerWidget {
  const LeadListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(filteredLeadsProvider);
    final statsAsync = ref.watch(leadStatsProvider);
    final currentFilter = ref.watch(leadFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260, // ✅ Increased height for Stats
            stretch: true,
            backgroundColor: isDark ? AppColors.cardDark : Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 205),
              title: Text("Lead Directory", style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, fontSize: 18)),
              background: Container(color: isDark ? AppColors.cardDark : Colors.white),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(200),
              child: Column(
                children: [
                  // SEARCH FIELD
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      onChanged: (val) => ref.read(searchProvider.notifier).state = val,
                      decoration: InputDecoration(
                        hintText: "Search leads...",
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // ✅ NEW: STATS CARDS ROW
                  statsAsync.maybeWhen(
                    data: (stats) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 20),
                      child: Row(
                        children: [
                          _StatCard(label: "Total", count: stats["Total"]!, color: Colors.blueAccent, isSelected: currentFilter == "All", onTap: () => ref.read(leadFilterProvider.notifier).state = "All"),
                          _StatCard(label: "Hot", count: stats["Hot"]!, color: Colors.redAccent, isSelected: currentFilter == "Hot", onTap: () => ref.read(leadFilterProvider.notifier).state = "Hot"),
                          _StatCard(label: "Warm", count: stats["Warm"]!, color: Colors.orangeAccent, isSelected: currentFilter == "Warm", onTap: () => ref.read(leadFilterProvider.notifier).state = "Warm"),
                          _StatCard(label: "Cold", count: stats["Cold"]!, color: Colors.lightBlue, isSelected: currentFilter == "Cold", onTap: () => ref.read(leadFilterProvider.notifier).state = "Cold"),
                        ],
                      ),
                    ),
                    orElse: () => const SizedBox(height: 70),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          leadsAsync.when(
            data: (leads) => leads.isEmpty 
              ? const SliverFillRemaining(child: Center(child: Text("No Leads Found")))
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _LeadCard(
                        lead: leads[index], 
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeadDetailScreen(leadId: leads[index].id)))
                      ),
                      childCount: leads.length,
                    ),
                  ),
                ),
            loading: () => const LeadShimmerList(),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text("Error: $e"))),
          ),
        ],
      ),
    );
  }
}

// ✅ NEW: MINI STAT CARD WIDGET
class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatCard({required this.label, required this.count, required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        width: 100,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : color)),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white70 : color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}



class _LeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;

  const _LeadCard({required this.lead, required this.onTap});

  Future<void> _launchWhatsApp(String phone, String company) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent("Hello! Reaching out from the sales team regarding $company.");
    final url = "https://wa.me/$cleanPhone?text=$msg";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // ✅ OVERDUE CALCULATION
    final now = DateTime.now();
    final bool isOverdue = lead.followUpDate != null && 
                           lead.followUpDate!.isBefore(DateTime(now.year, now.month, now.day)) &&
                           lead.status?.toLowerCase() != "closed";

    final String followUp = lead.followUpDate != null
        ? "${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year}"
        : "Not set";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        // ✅ VISUAL ALERT FOR OVERDUE
        border: isOverdue 
            ? Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.5) 
            : null,
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
              if (isOverdue) ...[
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Text(
                      "OVERDUE FOLLOW-UP", 
                      style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
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
                  _StatusChip(status: lead.status ?? "New"),
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
                        icon: Icons.chat_bubble_outline_rounded,
                        color: const Color(0xFF25D366),
                        onTap: () => _launchWhatsApp(lead.mobile, lead.companyName),
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
                      color: isOverdue ? Colors.redAccent.withOpacity(0.1) : AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_note_rounded, 
                          size: 14, 
                          color: isOverdue ? Colors.redAccent : AppColors.primary
                        ),
                        const SizedBox(width: 6),
                        Text(
                          followUp,
                          style: TextStyle(
                            fontSize: 11, 
                            fontWeight: FontWeight.bold, 
                            color: isOverdue ? Colors.redAccent : AppColors.primary
                          ),
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
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
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
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
    );
  }
}