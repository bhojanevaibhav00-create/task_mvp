import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/database_provider.dart';

// 🔹 PROVIDER: Watches the leads collection in Firebase for real-time counts
final leadSummaryProvider = StreamProvider<Map<String, int>>((ref) {
  return FirebaseFirestore.instance.collection('leads').snapshots().map((snapshot) {
    final docs = snapshot.docs;
    final now = DateTime.now();

    return {
      'all': docs.length,
      'today': docs.where((doc) {
        final timestamp = doc.data()['createdAt'] as Timestamp?;
        if (timestamp == null) return false;
        final date = timestamp.toDate();
        return date.day == now.day && date.month == now.month && date.year == now.year;
      }).length,
      'hot': docs.where((doc) => doc.data()['status'] == 'Hot').length,
      'warm': docs.where((doc) => doc.data()['status'] == 'Warm').length,
      'cold': docs.where((doc) => doc.data()['status'] == 'Cold').length,
      'lost': docs.where((doc) => doc.data()['status'] == 'Lost').length,
      'closed': docs.where((doc) => doc.data()['status'] == 'Closed').length,
    };
  });
});

class LeadDashboardScreen extends ConsumerWidget {
  const LeadDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summaryAsync = ref.watch(leadSummaryProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Lead Management",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        elevation: 0,
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error loading data: $err")),
        data: (counts) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Dashboard Overview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),

              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _DashboardCard(
                    title: "Today's Leads", 
                    count: counts['today'].toString(), 
                    icon: Icons.today,
                  ),
                  _DashboardCard(
                    title: "All Leads", 
                    count: counts['all'].toString(), 
                    icon: Icons.analytics,
                  ),
                  _DashboardCard(
                    title: "Closed Leads", 
                    count: counts['closed'].toString(), 
                    icon: Icons.check_circle, 
                    color: Colors.green,
                  ),
                  _DashboardCard(
                    title: "Hot Leads", 
                    count: counts['hot'].toString(), 
                    icon: Icons.local_fire_department, 
                    color: Colors.deepOrange,
                  ),
                  _DashboardCard(
                    title: "Warm Leads", 
                    count: counts['warm'].toString(), 
                    icon: Icons.wb_sunny, 
                    color: Colors.orange,
                  ),
                  _DashboardCard(
                    title: "Cold Leads", 
                    count: counts['cold'].toString(), 
                    icon: Icons.ac_unit, 
                    color: Colors.blue,
                  ),
                  _DashboardCard(
                    title: "Lost Leads", 
                    count: counts['lost'].toString(), 
                    icon: Icons.thumb_down, 
                    color: Colors.grey,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/add-lead'),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text("Add Lead", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/lead-list'),
                      icon: const Icon(Icons.list),
                      label: const Text("View Leads"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
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

class _DashboardCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color? color;

  const _DashboardCard({
    required this.title, 
    required this.count, 
    required this.icon, 
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color ?? AppColors.primary,
                ),
              ),
              Icon(icon, color: (color ?? AppColors.primary).withOpacity(0.5), size: 28),
            ],
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}