import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_mvp/core/constants/app_colors.dart';
import 'package:task_mvp/core/theme/app_text_styles.dart';
import 'package:task_mvp/core/theme/theme_controller.dart';

// ✅ Global Notifications Provider
final notificationsProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key}); // Changed to const for optimization

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsEnabled = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,

      // ================= APP BAR (Synced with Dashboard style) =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

          // ================= DARK MODE =================
          _settingTile(
            icon: Icons.dark_mode,
            label: 'Dark Mode',
            isDark: isDark,
            trailing: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.themeMode,
              builder: (_, mode, __) {
                return Switch(
                  value: mode == ThemeMode.dark,
                  onChanged: (_) => ThemeController.toggleTheme(),
                  activeColor: AppColors.primary,
                );
              },
            ),
          ),

          // ================= NOTIFICATIONS =================
          _settingTile(
            icon: Icons.notifications,
            label: 'Notifications',
            isDark: isDark,
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (v) => ref.read(notificationsProvider.notifier).state = v,
              activeColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Account'),

          _settingTile(
            icon: Icons.person,
            label: 'Profile',
            isDark: isDark,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          _settingTile(
            icon: Icons.lock,
            label: 'Change Password',
            isDark: isDark,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
          ),

          const SizedBox(height: 24),
          _sectionTitle('About'),

          _settingTile(
            icon: Icons.info_outline,
            label: 'App Version',
            isDark: isDark,
            trailing: Text('1.0.0', style: AppTextStyles.body.copyWith(color: isDark ? Colors.white70 : Colors.black54)),
          ),
          _settingTile(
            icon: Icons.help_outline,
            label: 'Help & Support',
            isDark: isDark,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
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

  // ================= SECTION TITLE =================
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

  // ================= SETTING TILE =================
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
        title: Text(label, style: AppTextStyles.body.copyWith(color: isDark ? Colors.white : Colors.black87)),
        trailing: trailing ?? Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.black26),
      ),
    );
  }

  // ================= LOGOUT DIALOG =================
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
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ================= SUB SCREENS (Placeholder logic) =================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Profile')));
}

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Change Password')));
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Help & Support')));
}