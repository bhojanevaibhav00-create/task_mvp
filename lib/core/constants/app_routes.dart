class AppRoutes {
  // ================= AUTH =================
  static const login = '/login';
  static const register = '/register';

  // ================= PROJECT MODULE =================
  static const dashboard = '/dashboard';
  static const tasks = '/tasks';
  static const taskDetails = '/task-details';
  static const createProject = '/project/create';
  static const projectDetails = '/projects/:projectId';
  static const projects = '/projects';

  // ================= LEAD MODULE (NEW SEPARATION) =================
  // ✅ These match the paths used in your appRouter.dart
  static const leadDashboard = '/lead-dashboard';
  static const addLead = '/add-lead';
  static const leadList = '/lead-list';
  static const leadReports = '/lead-reports';

  // ================= OTHER =================
  static const notifications = '/notifications';
  static const demo = '/demo';
  static const test = '/test';
}