import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../data/database/database.dart';
import 'lead_detail_screen.dart';

// 🔹 PROVIDER: Fetches leads from Drift and allows searching
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
      appBar: AppBar(
        title: const Text("All Leads", style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              onChanged: (val) => ref.read(searchProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: "Search company or contact...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? AppColors.scaffoldDark : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: leadsAsync.when(
        data: (leads) {
          if (leads.isEmpty) {
            return const Center(child: Text("No Leads Found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: leads.length,
            itemBuilder: (context, index) {
              final lead = leads[index];
              return InkWell(
                onTap: () {
                  // Connect to the detail screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeadDetailScreen(leadId: lead.id),
                    ),
                  );
                },
                child: _LeadCard(
                  companyName: lead.companyName,
                  contactPerson: lead.contactPersonName,
                  mobile: lead.mobile,
                  status: lead.status,
                  followUp: lead.followUpDate != null
                      ? "${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year}"
                      : "No Follow-up",
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final String companyName;
  final String contactPerson;
  final String mobile;
  final String status;
  final String followUp;

  const _LeadCard({
    required this.companyName,
    required this.contactPerson,
    required this.mobile,
    required this.status,
    required this.followUp,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  companyName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 8),
          Text(contactPerson, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 4),
          Text(mobile, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text("Follow-up: $followUp", style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            ],
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
      case "hot": color = Colors.red; break;
      case "warm": color = Colors.orange; break;
      case "cold": color = Colors.blue; break;
      case "lost": color = Colors.grey; break;
      case "closed": color = Colors.green; break;
      default: color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}