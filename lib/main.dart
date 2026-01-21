import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

void main() {
  runApp(const TaskMVPApp());
}

class TaskMVPApp extends StatefulWidget {
  const TaskMVPApp({super.key});

  @override
  State<TaskMVPApp> createState() => _TaskMVPAppState();
}

class _TaskMVPAppState extends State<TaskMVPApp> {
  bool isDark = false;

  void toggleTheme() {
    setState(() {
      isDark = !isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task MVP',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: DashboardScreen(onToggleTheme: toggleTheme),
    );
  }
}
