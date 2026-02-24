import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/providers/task_providers.dart';
import 'core/providers/theme_provider.dart';
import 'core/routes/app_router.dart';
import 'core/providers/database_provider.dart';
import 'data/database/database.dart' as db;
import 'package:drift/drift.dart' as drift;

/// 🚀 Database Seeding logic
Future<void> seedProjectData(db.AppDatabase database) async {
  try {
    final existingProjects = await database.select(database.projects).get();

    if (existingProjects.isEmpty) {
      await database.transaction(() async {
        await database
            .into(database.projects)
            .insert(
              db.ProjectsCompanion.insert(
                id: const drift.Value(1),
                name: 'General Project',
                color: const drift.Value(0xFF2196F3),
              ),
              mode: drift.InsertMode.insertOrIgnore,
            );
      });
      debugPrint("✅ Default Project Created");
    }
  } catch (e) {
    debugPrint("❌ Seed Error: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: AppBootstrap()));
}

class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final database = ref.read(databaseProvider);
      await seedProjectData(database);

      final reminder = ref.read(reminderServiceProvider);
      await reminder.init();
      await reminder.requestPermission();
      await reminder.resyncOnAppStart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2196F3),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF2196F3),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      routerConfig: appRouter, // ✅ THIS IS THE FIX
    );
  }
}
