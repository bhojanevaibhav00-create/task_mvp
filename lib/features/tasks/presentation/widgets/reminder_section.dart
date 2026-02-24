import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_mvp/core/constants/app_colors.dart';

class ReminderSection extends StatefulWidget {
  final bool initialEnabled;
  final DateTime? initialTime;
  final void Function(bool, DateTime?) onChanged;

  const ReminderSection({
    super.key,
    required this.initialEnabled,
    required this.initialTime,
    required this.onChanged,
  });

  @override
  State<ReminderSection> createState() => _ReminderSectionState();
}

class _ReminderSectionState extends State<ReminderSection> {
  late bool enabled;
  DateTime? reminderAt;

  @override
  void initState() {
    super.initState();
    enabled = widget.initialEnabled;
    reminderAt = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Icon(
          enabled ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        'Reminder',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: textColor,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        enabled && reminderAt != null
            ? DateFormat.yMMMd().add_jm().format(reminderAt!)
            : 'Enable reminder',
        style: TextStyle(
          color: enabled ? AppColors.primary : Colors.grey,
          fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Switch.adaptive(
        value: enabled,
        activeColor: AppColors.primary,
        onChanged: (v) {
          if (v) {
            _pickDateTime();
          } else {
            setState(() {
              enabled = false;
              reminderAt = null;
            });
            widget.onChanged(false, null);
          }
        },
      ),
      onTap: enabled ? _pickDateTime : null,
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: reminderAt ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(reminderAt ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      enabled = true;
      reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });

    widget.onChanged(enabled, reminderAt);
  }
}