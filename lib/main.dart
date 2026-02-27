import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'core/providers/task_providers.dart';
import 'core/providers/theme_provider.dart';
import 'core/routes/app_router.dart';
import 'core/providers/database_provider.dart';
import 'data/database/database.dart' as db;
import 'package:drift/drift.dart' as drift;
import 'package:task_mvp/core/services/fcm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🚀 Database Seeding logic
Future<void> seedProjectData(db.AppDatabase database) async {
  try {
    final existingProjects = await database.select(database.projects).get();

    if (existingProjects.isEmpty) {
      await database.transaction(() async {
        await database.into(database.projects).insert(
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

/// 🔥 BACKGROUND HANDLER (Required for FCM)
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);

  // 🔥 Register background handler
  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);

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

      // ✅ FCM initialization
     final fcmService = ref.read(fcmServiceProvider);
      await fcmService.initialize();

      // ✅ Save FCM token
      await _saveFcmToken();
    });
  }

  /// 🔥 SAVE DEVICE TOKEN TO FIRESTORE
  Future<void> _saveFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    final user = FirebaseAuth.instance.currentUser;

    if (token == null || user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'fcmToken': token,
    }, SetOptions(merge: true));

    debugPrint("✅ FCM Token Saved");
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
      routerConfig: appRouter,
    );
  }
}