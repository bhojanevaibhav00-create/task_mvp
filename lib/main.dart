import 'package:flutter/material.dart';

// Theme
import 'presentation/theme/app_theme.dart';

// Screens
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/signup_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/projects/project_list_screen.dart';
import 'presentation/screens/tasks/task_list_screen.dart';
import 'presentation/screens/tasks/create_task_screen.dart';
import 'presentation/screens/tasks/task_details_screen.dart';
import 'presentation/screens/notifications/notifications_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/projects': (context) => const ProjectListScreen(),
        '/tasks': (context) => const TaskListScreen(),
        '/create_task': (context) => const CreateTaskScreen(),
        '/task_details': (context) => const TaskDetailsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
