import 'package:flutter/material.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import 'app.dart';
import 'core/providers/task_providers.dart';
import 'core/providers/theme_provider.dart'; 
import 'data/database/database.dart' as db;
import 'package:task_mvp/core/providers/database_provider.dart';

// 🚀 Database Seeding logic
Future<void> seedProjectData(db.AppDatabase database) async {
  try {
    final existingUsers = await database.select(database.users).get();

    if (existingUsers.isEmpty) {
      await database.transaction(() async {
        // ✅ Insert User 1 (Admin)
        final userId = await database.into(database.users).insert(
          db.UsersCompanion.insert(
            name: 'Vaibhav Bhojane',
            email: 'vaibhav@jbbtechnologies.com',
            password: 'password123',
          ),
        );

        // ✅ Ensure Default Project exists
        await database.into(database.projects).insert(
          db.ProjectsCompanion.insert(
            id: const drift.Value(1),
            name: 'General Project',
            color: const drift.Value(0xFF2196F3),
          ),
          mode: drift.InsertMode.insertOrIgnore,
        );

        // ✅ Add Owner relationship
        await database.into(database.projectMembers).insert(
          db.ProjectMembersCompanion.insert(
            projectId: 1,
            userId: userId,
            role: 'Owner',
          ),
        );

        // ✅ Team Users
        await database.into(database.users).insert(
          db.UsersCompanion.insert(
            name: 'Ajinkya Ghode',
            email: 'ajinkya@test.com',
            password: 'password123',
          ),
        );

        await database.into(database.users).insert(
          db.UsersCompanion.insert(
            name: 'Vaishnavi Mogal',
            email: 'vaishnavi@test.com',
            password: 'password123',
          ),
        );
      });
      debugPrint("✅ Database Seeded Successfully");
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
    Future.microtask(() async {
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
    // Watch the themeMode to trigger the top-level rebuild
    final themeMode = ref.watch(themeModeProvider);

    return MyApp(themeMode: themeMode); // ✅ Parameter name fixed
  }
}