import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  const SettingsScreen({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: isDark,
            onChanged: (_) => onToggleTheme(),
          ),
          SwitchListTile(
            title: const Text("Notifications"),
            value: true,
            onChanged: (_) {},
          ),
          SwitchListTile(
            title: const Text("Sound"),
            value: false,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}
