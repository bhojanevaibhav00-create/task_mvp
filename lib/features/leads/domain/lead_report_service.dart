import '../../../lead_model/lead_model.dart';

class LeadReportService {
  // Uses LeadModel and the Enum for accurate counting
  static Map<String, int> getClosureSummary(List<LeadModel> leads) {
    return {
      'Closed': leads.where((l) => l.status == LeadStatus.closed).length,
      'Lost': leads.where((l) => l.status == LeadStatus.lost).length,
    };
  }
  
static List<double> getWeeklyLeadsData(List<LeadModel> leads) {
  final now = DateTime.now();
  // Initialize a list of 7 doubles (Mon-Sun) starting with 0.0
  List<double> dailyCounts = List.filled(7, 0.0);

  for (var lead in leads) {
    if (lead.createdAt != null) {
      // Find leads created within the last 7 days
      final difference = now.difference(lead.createdAt!).inDays;
      if (difference >= 0 && difference < 7) {
        // Adjust index based on weekday (0 is Monday)
        int dayIndex = lead.createdAt!.weekday - 1; 
        dailyCounts[dayIndex]++;
      }
    }
  }
  return dailyCounts;
}
  static List<LeadModel> getMissedLeads(List<LeadModel> leads) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    return leads.where((l) {
      if (l.followUpDate == null) return false;
      // Missed = Date is before today AND not already finished
      return l.followUpDate!.isBefore(todayStart) && 
             l.status != LeadStatus.closed && 
             l.status != LeadStatus.lost;
    }).toList();
  }
}