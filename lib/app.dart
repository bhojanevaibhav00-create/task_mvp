import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/providers/theme_provider.dart';

class MyApp extends ConsumerWidget {
  final ThemeMode themeMode;

  const MyApp({
    super.key, 
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the provider to stay in sync with the Settings toggle
    final currentTheme = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Task MVP',
      debugShowCheckedModeBanner: false,

      // Apply the themes from your AppTheme file
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      
      // ✅ CRITICAL: Using the watched themeMode
      themeMode: currentTheme, 

      routerConfig: appRouter,
    );
  }
}