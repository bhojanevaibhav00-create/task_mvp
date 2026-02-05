import 'package:flutter/material.dart';
import 'package:task_mvp/core/routes/app_router.dart';
import 'package:task_mvp/core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Task MVP',
      debugShowCheckedModeBanner: false,

      // 🌗 Theme support
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // 🚀 App navigation handled ONLY by GoRouter
      routerConfig: appRouter,
    );
  }
}