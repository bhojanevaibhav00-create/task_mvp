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
    // 💡 KEY FIX: Determine visual brightness to sync the switch on app start
    final isVisualDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: isVisualDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
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

          // 🌙 DARK MODE SWITCH - UPDATED FOR STARTUP SYNC
          _settingTile(
            icon: isVisualDark ? Icons.dark_mode : Icons.light_mode,
            label: 'Dark Mode',
            isDark: isVisualDark,
            trailing: Switch(
              // ✅ Sync with visual state so it's ON if the app is dark at startup
              value: isVisualDark, 
              onChanged: (_) {
                // Uses the robust toggle logic from your ThemeNotifier
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
              activeColor: AppColors.primary,
            ),
          ),

          // 🔔 NOTIFICATIONS
          _settingTile(
            icon: Icons.notifications,
            label: 'Notifications',
            isDark: isVisualDark,
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
            isDark: isVisualDark,
            onTap: () => _push(context, const ProfileScreen()),
          ),
          _settingTile(
            icon: Icons.lock,
            label: 'Change Password',
            isDark: isVisualDark,
            onTap: () => _push(context, const ChangePasswordScreen()),
          ),

          const SizedBox(height: 24),
          _sectionTitle('About'),

          _settingTile(
            icon: Icons.info_outline,
            label: 'App Version',
            isDark: isVisualDark,
            trailing: Text(
              '1.0.0',
              style: AppTextStyles.body.copyWith(
                color: isVisualDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),

          _settingTile(
            icon: Icons.logout,
            label: 'Logout',
            isDark: isVisualDark,
            onTap: () => _showLogoutDialog(context, isVisualDark),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          color: AppColors.primary,
          letterSpacing: 1.5,
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
        borderRadius: BorderRadius.circular(16),
        side: isDark 
            ? BorderSide(color: Colors.white.withOpacity(0.05)) 
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
          style: AppTextStyles.body.copyWith(
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

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout', 
          style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Text('Are you sure you want to logout?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
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
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Profile')));
}

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Change Password')));
}