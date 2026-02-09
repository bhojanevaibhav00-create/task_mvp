import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';

// AUTH
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';

// DASHBOARD
import '../../features/dashboard/presentation/dashboard_screen.dart';

// TASKS ✅
import '../../features/tasks/presentation/task_list_screen.dart';

// PROJECTS
import '../../features/projects/presentation/screens/project_detail_screen.dart';
import '../../features/projects/presentation/screens/create_project_screen.dart';

// OTHER
import '../../features/notifications/presentation/notification_screen.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.login,

  routes: [
    /// ================= AUTH =================
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),

    /// ================= DASHBOARD =================
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),

    /// ================= TASKS (🔥 THIS WAS MISSING) =================
    GoRoute(
      path: AppRoutes.tasks, // '/tasks'
      builder: (context, state) => const TaskListScreen(),
    ),

    /// ================= CREATE PROJECT =================
    GoRoute(
      path: AppRoutes.createProject,
      builder: (context, state) => const CreateProjectScreen(),
    ),

    /// ================= PROJECT DETAIL =================
    GoRoute(
      path: '/projects/:projectId',
      builder: (context, state) {
        final projectId =
        int.tryParse(state.pathParameters['projectId'] ?? '');
        if (projectId == null) {
          return const Scaffold(
            body: Center(child: Text('Invalid Project ID')),
          );
        }
        return ProjectDetailScreen(projectId: projectId);
      },
    ),

    /// ================= NOTIFICATIONS =================
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationScreen(),
    ),
  ],
);