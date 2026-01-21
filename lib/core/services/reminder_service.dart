import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../data/database/database.dart';

class ReminderService {
  final AppDatabase _db;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  ReminderService(this._db);

  // ================= INIT =================
  Future<void> init() async {
    tzdata.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);

    const channel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Task reminder notifications',
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ================= PERMISSION =================
  Future<void> requestPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
  }

  // ================= SCHEDULE =================
  Future<void> schedule(Task task) async {
    if (task.reminderEnabled != true || task.reminderAt == null) return;

    await _plugin.zonedSchedule(
      task.id,
      'Task Reminder',
      task.title,
      tz.TZDateTime.from(task.reminderAt!, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ================= CANCEL =================
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  // ================= RESYNC (VERY IMPORTANT) =================
  Future<void> resyncOnAppStart() async {
    final tasks = await (_db.select(_db.tasks)
          ..where((t) => t.reminderEnabled.equals(true))
          ..where((t) => t.reminderAt.isNotNull())
          ..where((t) => t.status.isNotValue('done')))
        .get();

    for (final task in tasks) {
      await schedule(task);
    }
  }
}
