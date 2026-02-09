import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import 'app.dart';
import 'core/providers/task_providers.dart';
import 'data/database/database.dart' as db;
import 'package:task_mvp/core/providers/database_provider.dart';
// 🚀 पायरी १: नवीन टेस्ट युजर्स ॲड करण्यासाठी 'Seed' फंक्शन अपडेट करा
Future<void> seedProjectData(db.AppDatabase database) async {
  try {
    final existingUsers = await database.select(database.users).get();
    
    // जर डेटाबेस रिकामा असेल, तरच डेटा ॲड करा
    if (existingUsers.isEmpty) {
      // १. स्वतःला (Vaibhav) मुख्य युजर म्हणून ॲड करा
      final userId = await database.into(database.users).insert(
        db.UsersCompanion.insert(
          name: 'Vaibhav Bhojane', 
          email: const drift.Value('vaibhav@jbbtechnologies.com'),
        ),
      );

      // २. प्रोजेक्ट आणि ओनरशिप सेट करा
      await database.into(database.projectMembers).insert(
        db.ProjectMembersCompanion.insert(
          projectId: 1,
          userId: userId,
          role: 'Owner',
        ),
      );

      // ३. आजच्या कामासाठी 'Ajinkya' आणि 'Vaishnavi' ला टेस्ट युजर्स म्हणून ॲड करा
      // यामुळे 'Add Member' डायलॉगमध्ये ही नावे दिसू लागतील
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

      debugPrint("✅ Database Seeded with Vaibhav, Ajinkya, and Vaishnavi");
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
    // 🚀 पायरी २: ॲप सुरू होताना डेटाबेस सीडिंग सुरू करा
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
  Widget build(BuildContext context) => const MyApp();
}