import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:task_mvp/core/constants/app_colors.dart';
import 'package:task_mvp/core/theme/app_text_styles.dart';
import 'package:task_mvp/core/providers/theme_provider.dart';

import 'profile_screen.dart';
import 'change_password_screen.dart';

final notificationsProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
final isVisualDark = themeMode == ThemeMode.dark;

    final notificationsEnabled = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor:
          isVisualDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          _sectionTitle('General'),

          /// Dark Mode
          _settingTile(
            icon: isVisualDark ? Icons.dark_mode : Icons.light_mode,
  label: 'Dark Mode',
  isDark: isVisualDark,
  trailing: Switch(
    value: isVisualDark,
    onChanged: (_) =>
        ref.read(themeModeProvider.notifier).toggleTheme(),
    activeColor: AppColors.primary,
  ),
),

          /// Notifications
          _settingTile(
            icon: Icons.notifications,
            label: 'Notifications',
            isDark: isVisualDark,
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (v) =>
                  ref.read(notificationsProvider.notifier).state = v,
              activeColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Account'),

          /// Profile
          _settingTile(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            isDark: isVisualDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProfileScreen()),
            ),
          ),

          /// Change Password
          _settingTile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            isDark: isVisualDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen()),
            ),
          ),

          const SizedBox(height: 24),
          _sectionTitle('About'),

          /// App Version
          _settingTile(
            icon: Icons.info_outline,
            label: 'App Version',
            isDark: isVisualDark,
            trailing: Text(
              '1.0.0',
              style: AppTextStyles.body.copyWith(
                color:
                    isVisualDark ? Colors.white38 : Colors.black26,
              ),
            ),
          ),

          /// Logout
          _settingTile(
            icon: Icons.logout_rounded,
            label: 'Logout',
            isDark: isVisualDark,
            onTap: () => _showLogoutDialog(context, isVisualDark),
          ),
        ],
      ),
    );
  }

  // ==========================
  // Section Title Widget
  // ==========================
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          color: AppColors.primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // ==========================
  // Setting Tile Widget
  // ==========================
  Widget _settingTile({
    required IconData icon,
    required String label,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: isDark ? AppColors.cardDark : Colors.white,
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? BorderSide(color: Colors.white.withOpacity(0.05))
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        trailing: trailing ??
            Icon(Icons.chevron_right,
                color: isDark ? Colors.white38 : Colors.black26),
      ),
    );
  }

  // ==========================
  // Logout Dialog (FIXED)
  // ==========================
  void _showLogoutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // ✅ Correct Logout Logic
              await FirebaseAuth.instance.signOut();
              // GoRouter redirect handles navigation automatically
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
