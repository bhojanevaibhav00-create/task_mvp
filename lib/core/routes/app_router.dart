import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';

// Auth Screens
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';

// Dashboard & Tasks
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/tasks/presentation/task_list_screen.dart';
import '../../features/tasks/presentation/task_create_edit_screen.dart';

// Notifications
import '../../features/notifications/presentation/notification_screen.dart';

// Project Screens (Sprint 7)
import '../../features/projects/presentation/screens/project_detail_screen.dart';

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
      path: '/projects/:projectId',
      builder: (context, state) {
        final projectId = int.parse(state.pathParameters['projectId']!);
        return ProjectDetailScreen(projectId: projectId);
      },
    ),

    // ================= TASKS =================
    
    // 1. Task List Screen
    GoRoute(
      path: AppRoutes.tasks, 
      builder: (context, state) => const TaskListScreen(),
    ),

    // 2. Create Task Route (Handles both /new and /create)
    // IMPORTANT: This must be defined BEFORE the dynamic :taskId route
    GoRoute(
      path: '/tasks/create', // ✅ Added to fix the 'create' FormatException
      builder: (context, state) {
        final projectIdStr = state.uri.queryParameters['projectId'];
        return TaskCreateEditScreen(
          projectId: projectIdStr != null ? int.tryParse(projectIdStr) : null,
        );
      },
    ),

    GoRoute(
      path: '/tasks/new', 
      builder: (context, state) {
        final projectIdStr = state.uri.queryParameters['projectId'];
        return TaskCreateEditScreen(
          projectId: projectIdStr != null ? int.tryParse(projectIdStr) : null,
        );
      },
    ),

    // 3. Edit Existing Task (Dynamic Route)
    GoRoute(
      path: '/tasks/:taskId', 
      builder: (context, state) {
        final taskIdStr = state.pathParameters['taskId'];
        
        // Safety check to ensure strings aren't parsed as integers
        if (taskIdStr == 'new' || taskIdStr == 'create') {
           return const TaskCreateEditScreen();
        }
        
        final taskId = int.parse(taskIdStr!);
        return TaskCreateEditScreen(taskId: taskId); 
      },
    ),

    // ================= NOTIFICATIONS =================
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationScreen(),
    ),

    // ================= DEMO / TEST =================
    GoRoute(
      path: AppRoutes.demo,
      builder: (context, state) => const DemoScreen(title: 'Demo Home Page'),
    ),
    GoRoute(
      path: AppRoutes.test,
      builder: (context, state) => const TestScreen(),
    ),
  ],
);