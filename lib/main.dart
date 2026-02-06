import 'package:flutter/material.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import 'app.dart';
import 'core/providers/task_providers.dart';
import 'data/database/database.dart' as db;

// 🚀 Database Seeding logic
Future<void> seedProjectData(db.AppDatabase database) async {
  try {
    final existingUsers = await database.select(database.users).get();

    if (existingUsers.isEmpty) {
      await database.transaction(() async {

        // ✅ Insert User 1
        final userId = await database.into(database.users).insert(
          db.UsersCompanion.insert(
            name: 'Vaibhav Bhojane',
            email: 'vaibhav@jbbtechnologies.com', // ✅ FIXED
            password: 'password123',              // ✅ FIXED
          ),
        );

        // ✅ Ensure Project exists
        await database.into(database.projects).insert(
          db.ProjectsCompanion.insert(
            id: const drift.Value(1), // OK because id is optional
            name: 'General Project',
            color: const drift.Value(0xFF2196F3), // optional field
          ),
          mode: drift.InsertMode.insertOrIgnore,
        );

        // ✅ Add Owner
        await database.into(database.projectMembers).insert(
          db.ProjectMembersCompanion.insert(
            projectId: 1,
            userId: userId,
            role: 'Owner',
          ),
        );

        // ✅ Insert User 2
        await database.into(database.users).insert(
          db.UsersCompanion.insert(
            name: 'Ajinkya Ghode',
            email: 'ajinkya@test.com', // ✅ FIXED
            password: 'password123',   // ✅ FIXED
          ),
        );

        // ✅ Insert User 3
        await database.into(database.users).insert(
          db.UsersCompanion.insert(
            name: 'Vaishnavi Mogal',
            email: 'vaishnavi@test.com', // ✅ FIXED
            password: 'password123',     // ✅ FIXED
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
    return const MyApp();
  }
}
