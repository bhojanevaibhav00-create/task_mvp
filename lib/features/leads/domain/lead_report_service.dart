import '../../../lead_model/lead_model.dart';

class LeadReportService {
  // Uses LeadModel and the Enum for accurate counting
  static Map<String, int> getClosureSummary(List<LeadModel> leads) {
    return {
      'Closed': leads.where((l) => l.status == LeadStatus.closed).length,
      'Lost': leads.where((l) => l.status == LeadStatus.lost).length,
    };
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