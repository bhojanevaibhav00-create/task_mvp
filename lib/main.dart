import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import 'app.dart';
import 'core/providers/task_providers.dart';
import 'data/database/database.dart' as db;


Future<void> seedProjectData(db.AppDatabase database) async {
  try {
    final existingUsers = await database.select(database.users).get();
    if (existingUsers.isNotEmpty) return;

    final userId = await database.into(database.users).insert(
      db.UsersCompanion.insert(
        name: 'Vaibhav Bhojane', 
        email: const drift.Value('vaibhav@jbbtechnologies.com'),
      ),
    );

    await database.into(database.projectMembers).insert(
      db.ProjectMembersCompanion.insert(
        projectId: 1,
        userId: userId,
        role: 'Owner',
      ),
    );
    debugPrint("✅ Database Seeded Successfully");
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
      final reminder = ref.read(reminderServiceProvider);
      await reminder.init();
      await reminder.requestPermission();
      await reminder.resyncOnAppStart();

      
    });
  }

  @override
  Widget build(BuildContext context) => const MyApp();
}