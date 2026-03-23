import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart' as db;
import 'database_provider.dart';

/// =======================================================
/// 1️⃣ CLEAN FIREBASE MEMBER MODEL
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

  String get id => uid;
  MemberWithUser get member => this;
  _UserProxy get user => _UserProxy(name);
}

class _UserProxy {
  final String name;
  _UserProxy(this.name);
}

/// =======================================================
/// 2️⃣ FETCH PROJECT MEMBERS FROM FIRESTORE (FINAL FIX)
/// =======================================================
final projectMembersProvider = StreamProvider.family
    .autoDispose<List<MemberWithUser>, int>((ref, projectId) {
  final firebaseUser = FirebaseAuth.instance.currentUser;

  if (firebaseUser == null) {
    return Stream.value([]);
  }

  final projectStream = FirebaseFirestore.instance
      .collection('projects')
      .doc(projectId.toString())
      .snapshots();

  return projectStream.asyncMap((snapshot) async {
    final data = snapshot.data();
    if (data == null) return [];

    final List<dynamic> membersList = data['members'] ?? [];
    final Map<String, dynamic> rolesMap =
        Map<String, dynamic>.from(data['roles'] ?? {});

    // 🔥 Fetch all users in parallel (IMPORTANT FIX)
    final futures = membersList.map((memberId) async {
      final String uid = memberId.toString().trim();

      // 🔥 ROLE FIX (MAIN BUG FIX)
      String role = rolesMap[uid]?.toString() ?? 'member';

      // sanitize role
      if (role.contains('.')) {
        role = role.split('.').last;
      }
      role = role.toLowerCase().trim();

      // fetch user
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final userData = userDoc.data();

      return MemberWithUser(
        uid: uid,
        name: userData?['name'] ?? 'Unknown User',
        role: role, // ✅ correct role
      );
    }).toList();

    return await Future.wait(futures);
  });
});

/// =======================================================
/// 3️⃣ COLLABORATION NOTIFIER (FIXED ROLE WRITE)
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
    final cleanUserId = userId.trim();
    final cleanRole = role.toLowerCase().trim();

    final projectRef = FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId.toString());

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(projectRef);

      Map<String, dynamic> roles = {};

      if (snapshot.exists) {
        final data = snapshot.data();
        roles = Map<String, dynamic>.from(data?['roles'] ?? {});
      }

      // ✅ FINAL FIX
      roles[cleanUserId] = cleanRole;

      transaction.set(
        projectRef,
        {
          'members': FieldValue.arrayUnion([cleanUserId]),
          'roles': roles,
        },
        SetOptions(merge: true),
      );
    });

    state = const AsyncValue.data(null);
  } catch (e, st) {
    state = AsyncValue.error(e, st);
  }
}
  Future<void> logActivity(
      int projectId, String action, String description) async {
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
      print('Log Error: $e');
    }
  }
}

final collaborationActionProvider =
    StateNotifierProvider<CollaborationNotifier, AsyncValue<void>>((ref) {
  return CollaborationNotifier(ref.watch(databaseProvider), ref);
});