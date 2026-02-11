import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';

// AUTH
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';

// DASHBOARD
import '../../features/dashboard/presentation/dashboard_screen.dart';


// TASKS
import '../../features/tasks/presentation/task_list_screen.dart';
import '../../features/tasks/presentation/task_create_edit_screen.dart';

// PROJECTS
import '../../features/projects/presentation/screens/project_detail_screen.dart';
import '../../features/projects/presentation/screens/create_project_screen.dart';

// DATA
import '../../data/database/database.dart'; // ✅ For Task type casting

// OTHER
import '../../features/notifications/presentation/notification_screen.dart';
import 'package:task_mvp/features/tasks/presentation/task_detail_screen.dart';
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
          return const Scaffold(body: Center(child: Text('Invalid Project ID')));
        }
        return ProjectDetailScreen(projectId: projectId);
      },
    ),

    /// ================= TASKS =================
    // 1. Task List
    GoRoute(
      path: AppRoutes.tasks,
      builder: (context, state) => const TaskListScreen(),
    ),

    // 2. Create Task (Static routes must come before dynamic /:taskId)
    GoRoute(
      path: '/tasks/create',
      builder: (context, state) {
        final pId = state.uri.queryParameters['projectId'];
        return TaskCreateEditScreen(projectId: pId != null ? int.tryParse(pId) : null);
      },
    ),
    GoRoute(
      path: '/tasks/new',
      builder: (context, state) {
        final pId = state.uri.queryParameters['projectId'];
        return TaskCreateEditScreen(projectId: pId != null ? int.tryParse(pId) : null);
      },
    ),

    // 3. ✅ FIXED: Dynamic Task Route (Handles /tasks/1, /tasks/2, etc.)
    GoRoute(
      path: '/tasks/:taskId',
      builder: (context, state) {
        final taskIdStr = state.pathParameters['taskId'];
        
        // If we passed the full task object via 'extra', use it.
        // Otherwise, the TaskDetailScreen should be updated to fetch by ID.
        if (state.extra is Task) {
          return TaskDetailScreen(task: state.extra as Task);
        }

        // Fallback: If no object is passed (deep link), handle error or fetch.
        return Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: const Center(child: Text("Task data missing. Navigate using 'extra: task'")),
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