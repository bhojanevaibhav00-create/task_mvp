import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  const SettingsScreen({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Dark Mode"),
            onChanged: (_) => onToggleTheme(),
            value: false,
          ),
        ],
      ),
    );
  }
}
