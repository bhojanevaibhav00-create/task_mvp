import 'package:flutter/material.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Task MVP',
      debugShowCheckedModeBanner: false,

      // Use the corrected AppTheme getter
      theme: AppTheme.lightTheme,

      // Router configuration
      routerConfig: appRouter,
    );
  }
}
