import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_routes.dart';

// AUTH
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';

// DASHBOARD
import '../../features/dashboard/presentation/dashboard_screen.dart';

// TASKS
import '../../features/tasks/presentation/task_list_screen.dart';
import '../../features/tasks/presentation/task_create_edit_screen.dart';
import '../../features/tasks/presentation/task_detail_screen.dart';

// PROJECTS
import '../../features/projects/presentation/screens/project_detail_screen.dart';
import '../../features/projects/presentation/screens/create_project_screen.dart';

// DATA
import '../../data/database/database.dart';

// OTHER
import '../../features/notifications/presentation/notification_screen.dart';

//  IMPORTS FOR THE NEW LEAD MODULE
import '../../features/leads/presentation/screens/lead_dashboard_screen.dart';
import '../../features/leads/presentation/screens/lead_list_screen.dart';
import '../../features/leads/presentation/screens/add_lead_screen.dart';
import '../../features/leads/presentation/screens/lead_report_screen.dart';

/// Auth notifier (refresh router on login/logout)
class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  debugLogDiagnostics: true,
  refreshListenable: AuthNotifier(),

  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final String location = state.uri.path;

    final bool isLogin = location == AppRoutes.login;
    final bool isRegister = location == AppRoutes.register;

    if (user == null) {
      if (isLogin || isRegister) return null;
      return AppRoutes.login;
    }

    if (isLogin || isRegister) return AppRoutes.dashboard;

    return null;
  },

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

    ///  ================= LEAD MANAGEMENT (NEW) =================
    GoRoute(
      path: '/lead-dashboard',
      builder: (context, state) => const LeadDashboardScreen(),
    ),

    GoRoute(
      path: '/add-lead',
      builder: (context, state) => const AddLeadScreen(),
    ),

    GoRoute(
      path: '/lead-list',
      builder: (context, state) => const LeadListScreen(),
    ),

    GoRoute(
      path: '/lead-reports',
      builder: (context, state) => const LeadReportScreen(),
    ),

    /// ================= PROJECTS =================
    GoRoute(
      path: AppRoutes.createProject,
      builder: (context, state) => const CreateProjectScreen(),
    ),

    GoRoute(
      path: '/projects/:projectId',
      builder: (context, state) {
        final projectIdStr = state.pathParameters['projectId'];
        final projectId = int.tryParse(projectIdStr ?? '');

        if (projectId == null) {
          return const Scaffold(
            body: Center(child: Text('Invalid Project ID')),
          );
        }

        return ProjectDetailScreen(projectId: projectId);
      },
    ),

    /// ================= TASKS =================
    GoRoute(
      path: AppRoutes.tasks,
      builder: (context, state) => const TaskListScreen(),
    ),

    GoRoute(
      path: '/tasks/create',
      builder: (context, state) {
        final pId = state.uri.queryParameters['projectId'];
        return TaskCreateEditScreen(
          projectId: pId != null ? int.tryParse(pId) : null,
        );
      },
    ),

    GoRoute(
      path: '/tasks/new',
      builder: (context, state) {
        final pId = state.uri.queryParameters['projectId'];
        return TaskCreateEditScreen(
          projectId: pId != null ? int.tryParse(pId) : null,
        );
      },
    ),

    GoRoute(
      path: '/tasks/:taskId',
      builder: (context, state) {
        if (state.extra is Task) {
          return TaskDetailScreen(task: state.extra as Task);
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: const Center(
            child: Text("Task data missing. Navigate using extra: task"),
          ),
        );
      },
    ),

    /// ================= NOTIFICATIONS =================
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationScreen(),
    ),
  ],
);