import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import 'package:task_mvp/core/providers/database_provider.dart';
import 'package:task_mvp/data/database/database.dart' as db;

/// =======================================================
/// 1️⃣ UPDATED MEMBER MODEL (FIXES UI ERRORS)
/// =======================================================

class MemberWithUser {
  final String uid;
  final String name;
  final String role;

  MemberWithUser({
    required this.uid,
    required this.name,
    required this.role,
  });

  // These getters fix the "member.user.name" and "member.member.role" errors
  MemberWithUser get member => this;
  _UserProxy get user => _UserProxy(name);
}

// Small helper to support member.user.name syntax
class _UserProxy {
  final String name;
  _UserProxy(this.name);
}

/// =======================================================
/// 2️⃣ FETCH PROJECT MEMBERS FROM FIRESTORE
/// =======================================================

final projectMembersProvider =
    StreamProvider.family.autoDispose<List<MemberWithUser>, int>(
        (ref, projectId) async* {
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

    final members = List<String>.from(data['members'] ?? []);
    final roles = Map<String, dynamic>.from(data['roles'] ?? {});

    final result = <MemberWithUser>[];

    for (final uid in members) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) continue;

      final userData = userDoc.data()!;

      result.add(
        MemberWithUser(
          uid: uid,
          name: userData['name'] ?? 'Unknown User',
          role: roles[uid] ?? 'member',
        ),
      );
    }

    yield result;
  }
});

/// =======================================================
/// 3️⃣ COLLABORATION NOTIFIER
/// =======================================================

class CollaborationNotifier extends StateNotifier<AsyncValue<void>> {
  final db.AppDatabase database;
  final Ref ref;

  CollaborationNotifier(this.database, this.ref)
      : super(const AsyncValue.data(null));

  Future<void> addMember({
    required int projectId,
    required String userId,
    required String role,
  }) async {
    state = const AsyncValue.loading();

    try {
      final projectRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId.toString());

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(projectRef);
        
        if (!snapshot.exists) {
          transaction.set(projectRef, {
            'members': [userId],
            'roles': {userId: role},
          });
        } else {
          final data = snapshot.data()!;
          final List<String> members = List<String>.from(data['members'] ?? []);
          final Map<String, dynamic> roles = Map<String, dynamic>.from(data['roles'] ?? {});

          if (!members.contains(userId)) {
            members.add(userId);
          }
          roles[userId] = role;

          transaction.update(projectRef, {
            'members': members,
            'roles': roles,
          });
        }
      });

      await logActivity(projectId, 'Member Added', 'User $userId added as $role');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logActivity(int projectId, String action, String description) async {
    try {
      await database.into(database.activityLogs).insert(
            db.ActivityLogsCompanion.insert(
              action: action,
              description: drift.Value(description),
              projectId: drift.Value(projectId),
              timestamp: drift.Value(DateTime.now()),
            ),
          );
    } catch (e) {
      print('Log error: $e');
    }
  }
}

final collaborationActionProvider =
    StateNotifierProvider<CollaborationNotifier, AsyncValue<void>>((ref) {
  return CollaborationNotifier(ref.watch(databaseProvider), ref);
});