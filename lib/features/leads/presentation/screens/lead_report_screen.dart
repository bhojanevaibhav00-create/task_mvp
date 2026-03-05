import 'dart:io';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  // ✅ NEW: CSV Export Logic for Management Reports
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
      appBar: AppBar(
        title: const Text("Performance Reports", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        elevation: 0,
      ),
      body: leadsAsync.when(
        data: (leads) {
          final summary = LeadReportService.getClosureSummary(leads);
          final missed = LeadReportService.getMissedLeads(leads);
          final hasData = summary['Closed']! > 0 || summary['Lost']! > 0;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _exportToCSV(context, leads),
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text("Export CSV"),
                ),
              ),

              const Text("Lead Closure Rate", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              // 🔹 PIE CHART
              SizedBox(
                height: 200,
                child: hasData 
                ? PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: summary['Closed']!.toDouble(),
                          color: Colors.green,
                          title: 'Closed\n${summary['Closed']}',
                          radius: 60,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        PieChartSectionData(
                          value: summary['Lost']!.toDouble(),
                          color: Colors.grey,
                          title: 'Lost\n${summary['Lost']}',
                          radius: 60,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : const Center(child: Text("No closed/lost data to visualize")),
              ),

              const SizedBox(height: 40),

              // 🔹 WEEKLY LEAD GENERATION BAR CHART
              const Text("Weekly Lead Generation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
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
                            return Text(days[value.toInt()], style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(7, (index) {
                      final weeklyData = LeadReportService.getWeeklyLeadsData(leads);
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: weeklyData[index],
                            color: AppColors.primary,
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 🔹 MISSED FOLLOW-UP REPORT
              Row(
                children: [
                  Text(
                    "Missed Follow-ups",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: missed.isNotEmpty ? Colors.red : Colors.green),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: missed.isNotEmpty ? Colors.red : Colors.green,
                    child: Text(missed.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              if (missed.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text("Great! No missed follow-ups."),
                )
              else
                ...missed.map((l) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    title: Text(l.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Overdue since: ${l.followUpDate?.day}/${l.followUpDate?.month}/${l.followUpDate?.year}"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {},
                  ),
                )).toList(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}