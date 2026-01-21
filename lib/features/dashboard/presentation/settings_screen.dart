import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const SettingsScreen({
    super.key,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Appearance"),
          _settingsTile(
            title: "Dark Mode",
            subtitle: "Reduce eye strain in low light",
            trailing: Switch(
              value: isDark,
              onChanged: (_) => onToggleTheme(),
            ),
          ),

          const SizedBox(height: 24),

          _sectionTitle("About"),
          _settingsTile(
            title: "App Version",
            subtitle: "Task MVP v1.0.0",
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        color: Colors.grey.shade100,
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}
