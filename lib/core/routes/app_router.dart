import 'package:go_router/go_router.dart';
import 'package:task_mvp/features/notifications/presentation/notification_screen.dart';
import '../constants/app_routes.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/tasks/presentation/task_list_screen.dart';


final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [

    GoRoute(
  path: AppRoutes.notifications,
  builder: (context, state) => const NotificationScreen(),
),

    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.tasks,
      builder: (context, state) => const TaskListScreen(),
    ),
  ],
);
