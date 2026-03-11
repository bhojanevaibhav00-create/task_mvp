import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/lead_providers.dart';
import '../../domain/lead_report_service.dart';
import '../../../../lead_model/lead_model.dart';

class LeadReportScreen extends ConsumerWidget {
  const LeadReportScreen({super.key});

  Future<void> _exportToCSV(BuildContext context, List<LeadModel> leads) async {
    List<List<dynamic>> rows = [];
    rows.add(["Company", "Contact", "Phone", "Status", "Product", "Follow-up"]);

    for (var lead in leads) {
      rows.add([
        lead.companyName,
        lead.contactPersonName,
        lead.mobile,
        lead.status.name,
        lead.productPitched ?? "",
        lead.followUpDate?.toIso8601String() ?? "N/A",
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/lead_report_${DateTime.now().millisecondsSinceEpoch}.csv";
    final file = File(path);
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(path)], text: 'Lead Management Report');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(leadsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
      body: leadsAsync.when(
        data: (leads) {
          final summary = LeadReportService.getClosureSummary(leads);
          final missed = LeadReportService.getMissedLeads(leads);
          final hasData = (summary['Closed'] ?? 0) > 0 || (summary['Lost'] ?? 0) > 0;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ================= PREMIUM APP BAR =================
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    "Performance Insights",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton.icon(
                      onPressed: () => _exportToCSV(context, leads),
                      icon: const Icon(Icons.ios_share_rounded, size: 20),
                      label: const Text("Export", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ),
                ],
              ),

              // ================= ANALYTICS CONTENT =================
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // --- SECTION 1: CLOSURE RATE ---
                    _buildReportCard(
                      title: "Conversion Funnel",
                      isDark: isDark,
                      child: hasData 
                      ? SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 50,
                              sections: [
                                _buildPieSection(summary['Closed']?.toDouble() ?? 0, Colors.greenAccent, "Won", isDark),
                                _buildPieSection(summary['Lost']?.toDouble() ?? 0, Colors.redAccent.withOpacity(0.6), "Lost", isDark),
                              ],
                            ),
                          ),
                        )
                      : _buildEmptyState("No conversion data yet"),
                    ),

                    const SizedBox(height: 24),

                    // --- SECTION 2: WEEKLY GENERATION ---
                    _buildReportCard(
                      title: "Weekly Generation",
                      isDark: isDark,
                      child: SizedBox(
                        height: 220,
                        child: BarChart(
                          _buildBarChartData(leads, isDark),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- SECTION 3: MISSED FOLLOW-UPS ---
                    _buildSectionHeader("Overdue Action Items", missed.isNotEmpty ? Colors.redAccent : Colors.green),
                    const SizedBox(height: 16),
                    
                    if (missed.isEmpty)
                      _buildSuccessState("All follow-ups are on track!")
                    else
                      ...missed.map((l) => _buildMissedLeadTile(l, isDark)).toList(),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }

  // ================= PREMIUM COMPONENT WIDGETS =================

  Widget _buildReportCard({required String title, required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.0)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  PieChartSectionData _buildPieSection(double value, Color color, String title, bool isDark) {
    return PieChartSectionData(
      value: value,
      color: color,
      title: '$title\n${value.toInt()}',
      radius: 30,
      titlePositionPercentageOffset: 1.8,
      titleStyle: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w900,
        fontSize: 11,
      ),
    );
  }

  BarChartData _buildBarChartData(List<LeadModel> leads, bool isDark) {
    final weeklyData = LeadReportService.getWeeklyLeadsData(leads);
    return BarChartData(
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              return Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(days[value.toInt()], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38)),
              );
            },
          ),
        ),
      ),
      barGroups: List.generate(7, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: weeklyData[index],
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              width: 14,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ],
    );
  }

  Widget _buildMissedLeadTile(LeadModel l, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.redAccent.withOpacity(0.05) : Colors.redAccent.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.redAccent.withOpacity(0.1),
          child: const Icon(Icons.priority_high_rounded, color: Colors.redAccent, size: 20),
        ),
        title: Text(l.companyName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        subtitle: Text("Overdue: ${l.followUpDate?.day}/${l.followUpDate?.month}"),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  Widget _buildEmptyState(String msg) => Center(child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13)));

  Widget _buildSuccessState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, color: Colors.green, size: 40),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }
}