import 'package:flutter/material.dart';

class MemberEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const MemberEmptyState({
    super.key,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('No members yet'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAdd,
            child: const Text('Add Member'),
          ),
        ],
      ),
    );
  }
}