import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import 'app.dart';
import 'core/providers/task_providers.dart';
import 'core/providers/theme_provider.dart';
import 'data/database/database.dart' as db;
import 'package:task_mvp/core/providers/database_provider.dart';

/// 🚀 Database Seeding logic (Only default project, no demo user)
Future<void> seedProjectData(db.AppDatabase database) async {
  try {
    final existingProjects =
        await database.select(database.projects).get();

    if (existingProjects.isEmpty) {
      await database.transaction(() async {
        // ✅ Ensure Default Project exists
        await database.into(database.projects).insert(
              db.ProjectsCompanion.insert(
                id: const drift.Value(1),
                name: 'General Project',
                color: const drift.Value(0xFF2196F3),
              ),
              mode: drift.InsertMode.insertOrIgnore,
            );
      });

      debugPrint("✅ Default Project Created (No Demo User)");
    }
  } catch (e) {
    debugPrint("❌ Seed Error: $e");
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

      // ✅ Only create default project (no demo user)
      await seedProjectData(database);

      // ✅ Reminder initialization (same as before)
      final reminder = ref.read(reminderServiceProvider);
      await reminder.init();
      await reminder.requestPermission();
      await reminder.resyncOnAppStart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MyApp(themeMode: themeMode);
  }
}
