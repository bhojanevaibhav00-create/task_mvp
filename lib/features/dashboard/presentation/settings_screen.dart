import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_mvp/core/constants/app_colors.dart';
import 'package:task_mvp/core/theme/app_text_styles.dart';
import 'package:task_mvp/core/theme/theme_controller.dart';

// Notifications Provider
final notificationsProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  SettingsScreen({super.key}); // ✅ non-const (safe)

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsEnabled = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,

      // ================= APP BAR (Dashboard style) =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Settings'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('General'),

          // ================= DARK MODE =================
          _settingTile(
            icon: Icons.dark_mode,
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

          // ================= NOTIFICATIONS =================
          _settingTile(
            icon: Icons.notifications,
            label: 'Notifications',
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (v) =>
              ref.read(notificationsProvider.notifier).state = v,
              activeColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Account'),

          _settingTile(
            icon: Icons.person,
            label: 'Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              );
            },
          ),
          _settingTile(
            icon: Icons.lock,
            label: 'Change Password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChangePasswordScreen()),
              );
            },
          ),

          const SizedBox(height: 24),
          _sectionTitle('About'),

          _settingTile(
            icon: Icons.info_outline,
            label: 'App Version',
            trailing: Text('1.0.0', style: AppTextStyles.body),
          ),
          _settingTile(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HelpScreen()),
              );
            },
          ),
          _settingTile(
            icon: Icons.logout,
            label: 'Logout',
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
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: AppTextStyles.body),
        trailing: trailing ?? const Icon(Icons.chevron_right),
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ================= SUB SCREENS =================

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key}); // ✅ non-const

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
    );
  }
}

class ChangePasswordScreen extends StatelessWidget {
  ChangePasswordScreen({super.key}); // ✅ non-const

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
    );
  }
}

class HelpScreen extends StatelessWidget {
  HelpScreen({super.key}); // ✅ non-const

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
    );
  }
}
