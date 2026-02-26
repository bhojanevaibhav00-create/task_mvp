import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import 'notification_providers.dart'; 
import 'package:task_mvp/core/providers/database_provider.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final allProjectsProvider =
    StreamProvider.autoDispose<List<Project>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final firebaseUser = FirebaseAuth.instance.currentUser;

  if (firebaseUser == null) {
    yield [];
    return;
  }

  final firestoreStream = FirebaseFirestore.instance
      .collection('projects')
      .where('members', arrayContains: firebaseUser.uid)
      .snapshots();

  await for (final snapshot in firestoreStream) {

    // 🔥 First sync Firestore → Drift
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final projectId = int.tryParse(doc.id);
      if (projectId == null) continue;

      await db.into(db.projects).insertOnConflictUpdate(
        ProjectsCompanion(
          id: drift.Value(projectId),
          name: drift.Value(data['name'] ?? ''),
          description: drift.Value(data['description']),
          color: drift.Value(data['color'] ?? 0xFF2196F3),
          createdAt: drift.Value(DateTime.now()),
        ),
      );
    }

    // 🔥 Then return Drift stream
    yield await db.select(db.projects).get();
  }
});
/// =======================================================
/// 2. PROJECT CONTROLLER PROVIDER
/// =======================================================
final projectControllerProvider = Provider((ref) => ProjectController(ref));

/// =======================================================
/// 3. PROJECT LOGIC CONTROLLER
/// =======================================================
class ProjectController {
  final Ref ref;
  ProjectController(this.ref);

  /// ✅ CREATE PROJECT WITH NOTIFICATION
  /// Inserts project into DB and triggers a workspace notification.
  Future<void> createProject(String name) async {
    final db = ref.read(databaseProvider);
    
    await db.into(db.projects).insert(
      ProjectsCompanion.insert(
        name: name,
        createdAt: drift.Value(DateTime.now()),
      ),
    );
    
    // ✅ Trigger notification via the NotificationNotifier
    await ref.read(notificationServiceProvider).sendNotification(
      title: "Project Created",
      body: "You created the project: $name",
      type: "project_create",
    );
  }

  /// ✅ DELETE PROJECT WITH NOTIFICATION
  /// Removes project from DB and alerts the user via notification.
  Future<void> deleteProject(int projectId, String projectName) async {
    final db = ref.read(databaseProvider);
    
    // 1. Delete the record from the projects table
    await (db.delete(db.projects)..where((t) => t.id.equals(projectId))).go();
    
    // 2. ✅ Trigger notification alerting the deletion
    await ref.read(notificationServiceProvider).sendNotification(
      title: "Project Deleted",
      body: "The project '$projectName' was removed.",
      type: "project_delete",
    );
  }
}