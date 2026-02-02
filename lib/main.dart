import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import 'app.dart';
import 'core/providers/task_providers.dart';
import 'core/constants/app_colors.dart'; // AppColors 
import 'data/database/database.dart' as db;

// 🚀 Database Seeding logic 
Future<void> seedProjectData(db.AppDatabase database) async {
  try {
    final existingUsers = await database.select(database.users).get();
    if (existingUsers.isEmpty) {
      final userId = await database.into(database.users).insert(
        db.UsersCompanion.insert(
          name: 'Vaibhav Bhojane', 
          email: const drift.Value('vaibhav@jbbtechnologies.com'),
        ),
      );

      await database.into(database.users).insert(
        db.UsersCompanion.insert(
          name: 'Ajinkya Ghode', 
          email: const drift.Value('ajinkya@test.com'),
        ),
      );

      await database.into(database.users).insert(
        db.UsersCompanion.insert(
          name: 'Vaishnavi Mogal', 
          email: const drift.Value('vaishnavi@test.com'),
        ),
      );
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
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task MVP',
      
      
      themeMode: ThemeMode.system, 
      
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FD),
        primaryColor: AppColors.primary,
        useMaterial3: true,
      ),
      
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.scaffoldDark, 
        primaryColor: AppColors.primary,
        useMaterial3: true,
      ),
      
      home: const MyApp(), 
    );
  }
}