import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class RoleChip extends StatelessWidget {
  final String role;

  const RoleChip({super.key, required this.role});

  Color get _bg {
    switch (role.toLowerCase()) {
      case 'owner':
        return Colors.purple.withOpacity(0.12);
      case 'admin':
        return Colors.blue.withOpacity(0.12);
      default:
        return Colors.grey.withOpacity(0.15);
    }
  }

  Color get _fg {
    switch (role.toLowerCase()) {
      case 'owner':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _fg,
        ),
      ),
    );
  }
}