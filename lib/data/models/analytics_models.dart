class DashboardStats {
  final int overdueCount;
  final double completionRate;
  final int createdThisWeek;
  final int completedThisWeek;

  DashboardStats({
    required this.overdueCount,
    required this.completionRate,
    required this.createdThisWeek,
    required this.completedThisWeek,
  });
}

class MemberStats {
  final String userName;
  final int assignedTasks;
  final int completedTasks;

  MemberStats({
    required this.userName,
    required this.assignedTasks,
    required this.completedTasks,
  });

  double get progress =>
      assignedTasks == 0 ? 0.0 : completedTasks / assignedTasks;
}
