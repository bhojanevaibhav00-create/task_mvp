import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database.dart';

class ExportRepository {
  final AppDatabase _db;

  ExportRepository(this._db);

  /// Exports tasks for a given project to a CSV file and triggers the share dialog.
  Future<void> exportProjectTasks(int projectId) async {
    // 1. Fetch Data: Join Tasks with Users to get Assignee Name
    final query = _db.select(_db.tasks).join([
      leftOuterJoin(_db.users, _db.users.id.equalsExp(_db.tasks.assigneeId)),
    ])..where(_db.tasks.projectId.equals(projectId));

    final results = await query.get();

    // 2. Build CSV Content
    final headers = [
      'Title',
      'Status',
      'Priority',
      'Due Date',
      'Assignee',
      'Created At',
      'Updated At',
    ];

    final buffer = StringBuffer();
    buffer.writeln(headers.join(','));

    for (final row in results) {
      final task = row.readTable(_db.tasks);
      final assignee = row.readTableOrNull(_db.users);

      final rowData = [
        _escape(task.title),
        _escape(task.status ?? 'Pending'),
        _priorityLabel(task.priority),
        task.dueDate?.toIso8601String().split('T').first ?? '',
        _escape(assignee?.name ?? 'Unassigned'),
        task.createdAt?.toIso8601String() ?? '',
        task.updatedAt?.toIso8601String() ?? '',
      ];

      buffer.writeln(rowData.join(','));
    }

    // 3. Save to Temporary File
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/project_${projectId}_tasks.csv';
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    // 4. Share File
    await Share.shareXFiles([
      XFile(filePath),
    ], text: 'Exported Tasks for Project $projectId');
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _priorityLabel(int? priority) {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'None';
    }
  }
}
