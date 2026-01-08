import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile & Settings")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text("Vaishnavi Mogal", style: AppTextStyles.heading),
            const SizedBox(height: 8),
            const Text("vaishnavi@example.com", style: AppTextStyles.body),
            const SizedBox(height: 24),

            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text("Notifications"),
              onTap: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
