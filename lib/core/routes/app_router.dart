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

/// 🔥 Auth notifier (refresh router on login/logout)
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

    // ✅ Correct way for latest GoRouter
    final String location = state.uri.path;

    final bool isLogin = location == AppRoutes.login;
    final bool isRegister = location == AppRoutes.register;

    // 🔴 NOT LOGGED IN
    if (user == null) {
      if (isLogin || isRegister) {
        return null; // allow login & register
      }
      return AppRoutes.login; // force login
    }

    // 🟢 LOGGED IN
    if (isLogin || isRegister) {
      return AppRoutes.dashboard; // prevent going back
    }

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
