import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/tasks/presentation/task_list_screen.dart';
import '../../features/demo/presentation/demo_screen.dart';
import '../../features/test/presentation/test_screen.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.test,
  routes: [
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
