import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_providers.dart';

class FCMService {
  final Ref ref;

  FCMService(this.ref);

  final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings);

    FirebaseMessaging.onMessage.listen((message) async {
      await _showNotification(message);
      await _saveToLocalDB(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _saveToLocalDB(message);
    });
  }

  Future<void> _saveToLocalDB(RemoteMessage message) async {
    final notifier = ref.read(notificationServiceProvider);

    await notifier.sendNotification(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      type: message.data['type'] ?? 'task',
    );
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      details,
      payload: jsonEncode(message.data),
    );
  }
}
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService(ref);
});