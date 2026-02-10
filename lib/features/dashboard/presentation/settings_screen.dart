import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/theme_provider.dart';

// Notifications toggle (UI only)
final notificationsProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,

      appBar: AppBar(
        elevation: 0,
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
        children: [
          _sectionTitle('General'),

          // 🌙 DARK MODE SWITCH (FIXED)
          _settingTile(
            icon: Icons.dark_mode,
            label: 'Dark Mode',
            isDark: isDark,
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (_) =>
                  ref.read(themeModeProvider.notifier).toggle(),
              activeColor: AppColors.primary,
            ),
          ),

          // 🔔 NOTIFICATIONS
          _settingTile(
            icon: Icons.notifications,
            label: 'Notifications',
            isDark: isDark,
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (v) => ref
                  .read(notificationsProvider.notifier)
                  .state = v,
              activeColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Account'),

          _settingTile(
            icon: Icons.person,
            label: 'Profile',
            isDark: isDark,
            onTap: () => _push(context, const ProfileScreen()),
          ),
          _settingTile(
            icon: Icons.lock,
            label: 'Change Password',
            isDark: isDark,
            onTap: () => _push(context, const ChangePasswordScreen()),
          ),

          const SizedBox(height: 24),
          _sectionTitle('About'),

          _settingTile(
            icon: Icons.info_outline,
            label: 'App Version',
            isDark: isDark,
            trailing: Text(
              '1.0.0',
              style: AppTextStyles.body.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),

          _settingTile(
            icon: Icons.logout,
            label: 'Logout',
            isDark: isDark,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

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
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        trailing: trailing ??
            Icon(Icons.chevron_right,
                color: isDark ? Colors.white38 : Colors.black26),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ===== PLACEHOLDERS =====

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Profile')));
}

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Change Password')));
}