import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      "Task 'Design Login' is due tomorrow",
      "Project 'Mobile App' has new updates",
      "Task 'API Integration' marked as Done",
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(notifications[index], style: AppTextStyles.body),
          );
        },
      ),
    );
  }
}
