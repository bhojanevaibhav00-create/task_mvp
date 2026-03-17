import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart' as db;
import 'database_provider.dart';

/// =======================================================
/// 1️⃣ CLEAN FIREBASE MEMBER MODEL (NO DRIFT DEPENDENCY)
/// =======================================================

class MemberWithUser {
  final String uid;
  final String name;
  final String role;

  MemberWithUser({required this.uid, required this.name, required this.role});

  // 🚀 ADD THIS LINE TO FIX THE 'user.id' ERROR
  String get id => uid;

  // Keep these for your other UI rows
  MemberWithUser get member => this;
  _UserProxy get user => _UserProxy(name);
}

class _UserProxy {
  final String name;
  _UserProxy(this.name);
}

/// =======================================================
/// 2️⃣ FETCH PROJECT MEMBERS FROM FIRESTORE
/// =======================================================

final projectMembersProvider = StreamProvider.family
    .autoDispose<List<MemberWithUser>, int>((ref, projectId) async* {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        yield [];
        return;
      }

      final projectStream = FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId.toString())
          .snapshots();

      await for (final snapshot in projectStream) {
        final data = snapshot.data();
        if (data == null) {
          yield [];
          continue;
        }

        // Safely parse members and roles to avoid TypeErrors if IDs were saved as integers
        final membersList = data['members'] as List<dynamic>? ?? [];
        final members = membersList.map((e) => e.toString().trim()).toList();
        final rawRoles = data['roles'] as Map<dynamic, dynamic>? ?? {};
        final roles = rawRoles.map((k, v) => MapEntry(k.toString().trim(), v));

        final result = <MemberWithUser>[];

        for (final uid in members) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          if (!userDoc.exists) continue;

          final userData = userDoc.data()!;

          // Sanitize role in case it was saved as an Enum string (e.g. 'ProjectRole.admin') or capitalized
          String rawRole = roles[uid]?.toString().trim() ?? 'member';
          if (rawRole.contains('.')) rawRole = rawRole.split('.').last;

          result.add(
            MemberWithUser(
              uid: uid,
              name: userData['name'] ?? 'Unknown User',
              role: rawRole.toLowerCase(),
            ),
          );
        }

        yield result;
      }
    });

/// =======================================================
/// 3️⃣ COLLABORATION NOTIFIER (HANDLES FIRESTORE + DRIFT)
/// =======================================================

class CollaborationNotifier extends StateNotifier<AsyncValue<void>> {
  final db.AppDatabase database;
  final Ref ref;

  CollaborationNotifier(this.database, this.ref)
    : super(const AsyncValue.data(null));

  /// Adds a member to Firestore and logs the action in local Drift DB
  Future<void> addMember({
    required int projectId,
    required String userId,
    required String role,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Ensure role is properly formatted string (e.g., 'admin' instead of 'ProjectRole.admin' or 'Admin')
      final cleanRole = role.contains('.')
          ? role.split('.').last.toLowerCase().trim()
          : role.toLowerCase().trim();
      final cleanUserId = userId.trim();

      final projectRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId.toString());

      // Update Firestore using a transaction for data integrity
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(projectRef);

        if (!snapshot.exists) {
          // If project doesn't exist in Firestore yet, create it
          transaction.set(projectRef, {
            'members': [cleanUserId],
            'roles': {cleanUserId: cleanRole},
          });
        } else {
          final data = snapshot.data()!;

          // Safely parse arrays and maps to prevent int vs String TypeErrors
          final membersList = data['members'] as List<dynamic>? ?? [];
          final members = membersList.map((e) => e.toString().trim()).toList();
          final rawRoles = data['roles'] as Map<dynamic, dynamic>? ?? {};
          final roles = rawRoles.map(
            (k, v) => MapEntry(k.toString().trim(), v),
          );

          if (!members.contains(cleanUserId)) {
            members.add(cleanUserId);
          }
          roles[cleanUserId] = cleanRole;

          transaction.update(projectRef, {'members': members, 'roles': roles});
        }
      });

      // Log activity to Drift
      await logActivity(
        projectId,
        'Member Added',
        'User $cleanUserId joined the project as $cleanRole',
      );

      // Sync local Drift database to ensure offline UI reflects the correct role
      try {
        final parsedId = int.tryParse(cleanUserId);
        if (parsedId != null) {
          await database
              .into(database.projectMembers)
              .insert(
                db.ProjectMembersCompanion.insert(
                  projectId: projectId,
                  userId: parsedId,
                  role: cleanRole,
                  joinedAt: drift.Value(DateTime.now()),
                ),
                mode: drift.InsertMode.insertOrReplace,
              );
        }
      } catch (e) {
        print('Drift sync error: $e');
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Logs activity to the local Drift database
  Future<void> logActivity(
    int projectId,
    String action,
    String description,
  ) async {
    try {
      await database
          .into(database.activityLogs)
          .insert(
            db.ActivityLogsCompanion.insert(
              action: action,
              description: drift.Value(description),
              projectId: drift.Value(projectId),
              timestamp: drift.Value(DateTime.now()),
            ),
          );
    } catch (e) {
      // We don't set global error state here to avoid breaking the UI
      // if only the logging fails but the Firestore update succeeded.
      print('Failed to log activity: $e');
    }
  }
}

/// =======================================================
/// 4️⃣ PROVIDER BINDING
/// =======================================================

final collaborationActionProvider =
    StateNotifierProvider<CollaborationNotifier, AsyncValue<void>>((ref) {
      return CollaborationNotifier(ref.watch(databaseProvider), ref);
    });
