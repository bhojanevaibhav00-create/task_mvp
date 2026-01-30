import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';

// Auth Screens
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';

// Dashboard & Tasks
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/tasks/presentation/task_list_screen.dart';

// Notifications
import '../../features/notifications/presentation/notification_screen.dart';

// Project Screens (Added for Sprint 7)
import '../../features/projects/presentation/screens/project_detail_screen.dart'; // ✅ Import your new screen

// Other Screens
import '../../features/demo/presentation/demo_screen.dart';
import '../../features/test/presentation/test_screen.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    // ================= AUTH =================
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),

    // ================= DASHBOARD =================
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),

    // ================= PROJECTS (Sprint 7) =================
    GoRoute(
      path: '/projects/:projectId', // Matches the path pushed from Dashboard
      builder: (context, state) {
        // Extract the ID from the URL path and convert to int
        final projectId = int.parse(state.pathParameters['projectId']!);
        return ProjectDetailScreen(projectId: projectId);
      },
    ),

    // ================= TASKS =================
    GoRoute(
      path: AppRoutes.tasks,
      builder: (context, state) => const TaskListScreen(),
    ),

    // ================= NOTIFICATIONS =================
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationScreen(),
    ),

    // ================= DEMO / TEST =================
    GoRoute(
      path: AppRoutes.demo,
      builder: (context, state) =>
          const DemoScreen(title: 'Demo Home Page'),
    ),
    GoRoute(
      path: AppRoutes.test,
      builder: (context, state) => const TestScreen(),
    ),
  ],
);