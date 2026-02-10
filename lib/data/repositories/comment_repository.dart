import 'package:drift/drift.dart';
import '../database/database.dart';
import 'notification_repository.dart';

class CommentRepository {
  final AppDatabase db;
  final NotificationRepository notificationRepo;

  CommentRepository(this.db, this.notificationRepo);

  // 1. Fetch comments with User details joined
  Stream<List<CommentWithUser>> watchComments(int taskId) {
    final query = db.select(db.comments).join([
      innerJoin(db.users, db.users.id.equalsExp(db.comments.userId)),
    ])
      ..where(db.comments.taskId.equals(taskId))
      ..orderBy([OrderingTerm.desc(db.comments.createdAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return CommentWithUser(
          comment: row.readTable(db.comments),
          user: row.readTable(db.users),
        );
      }).toList();
    });
  }

  // 2. Save Comment & Process Mentions
  Future<void> addComment({
    required int taskId,
    required int userId,
    required String content,
    int? projectId,
  }) async {
    // A) Insert Comment into DB
    await db.into(db.comments).insert(
          CommentsCompanion.insert(
            taskId: taskId,
            userId: userId,
            content: content,
            createdAt: Value(DateTime.now()),
          ),
        );

    // B) Logic: Scan for @mentions using Regex
    // This matches @ followed by word characters (names)
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(content);

    if (matches.isNotEmpty) {
      for (final match in matches) {
        final mentionedName = match.group(1);
        if (mentionedName != null) {
          await _handleMentionNotification(mentionedName, taskId, projectId, content);
        }
      }
    }
  }

  // C) Internal Helper: Trigger Notification if user exists
  Future<void> _handleMentionNotification(
    String name, 
    int taskId, 
    int? projectId, 
    String originalContent
  ) async {
    // Find the user by name
    final user = await (db.select(db.users)..where((u) => u.name.equals(name))).getSingleOrNull();

    if (user != null) {
      await notificationRepo.addNotification(
        title: "You were mentioned",
        message: "A teammate mentioned you in a comment: \"$originalContent\"",
        type: "mention",
        taskId: taskId,
        projectId: projectId,
      );
    }
  }
}

// Data Transfer Object for UI
class CommentWithUser {
  final Comment comment;
  final User user;
  CommentWithUser({required this.comment, required this.user});
}