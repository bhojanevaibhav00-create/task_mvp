import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_mvp/core/constants/app_colors.dart';
import 'package:task_mvp/core/theme/app_text_styles.dart';
import 'package:task_mvp/core/theme/theme_controller.dart';

// Notifications Provider
final notificationsProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsEnabled = ref.watch(notificationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.primary, // consistent color
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(context, 'General'),

          // Dark Mode Toggle
          _settingTile(
            icon: Icons.dark_mode,
            iconColor: AppColors.primary,
            label: 'Dark Mode',
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

          // Notifications Toggle
          _settingTile(
            icon: Icons.notifications,
            iconColor: AppColors.primary,
            label: 'Notifications',
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (v) => ref.read(notificationsProvider.notifier).state = v,
              activeColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 24),
          _sectionTitle(context, 'Account'),

          _settingTile(
            icon: Icons.person,
            iconColor: AppColors.primary,
            label: 'Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          _settingTile(
            icon: Icons.lock,
            iconColor: AppColors.primary,
            label: 'Change Password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),

          const SizedBox(height: 24),
          _sectionTitle(context, 'About'),

          _settingTile(
            icon: Icons.info_outline,
            iconColor: AppColors.primary,
            label: 'App Version',
            trailing: Text('1.0.0', style: AppTextStyles.body),
          ),
          _settingTile(
            icon: Icons.help_outline,
            iconColor: AppColors.primary,
            label: 'Help & Support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
          ),
          _settingTile(
            icon: Icons.logout,
            iconColor: AppColors.primary,
            label: 'Logout',
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  // =========================
  // Section Title
  // =========================
  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.primary, // consistent color
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // =========================
  // Setting Tile
  // =========================
  Widget _settingTile({
    required IconData icon,
    required String label,
    Color iconColor = Colors.black,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: AppColors.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor),
        title: Text(label, style: AppTextStyles.body),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  // =========================
  // Logout Dialog
  // =========================
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement logout logic
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// =========================
// Profile / Change Password / Help Screens
// =========================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Profile')));
  }
}

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Change Password')));
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Help & Support')));
  }
}
