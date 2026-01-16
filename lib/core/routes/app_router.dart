import 'package:go_router/go_router.dart';

// Auth Screens
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';

// Dashboard & Tasks
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/tasks/presentation/task_list_screen.dart';
//import '../../features/dashboard/presentation/dashboard_screen.dart';

// Other Screens
import '../../features/demo/presentation/demo_screen.dart';
import '../../features/test/presentation/test_screen.dart';

// App Routes
import '../constants/app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.test,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) {
        // Pass a dummy toggle or a real one if you have state
        return DashboardScreen(
          onToggleTheme: () {
            // You can implement your theme toggle logic here
            print("Theme toggled");
          },
        );
      },
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
