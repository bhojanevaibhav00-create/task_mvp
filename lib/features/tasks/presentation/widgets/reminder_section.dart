import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  String? error;

  @override
  void initState() {
    super.initState();
    enabled = widget.initialEnabled;
    reminderAt = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          "Reminder",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Enable Reminder"),
          value: enabled,
          onChanged: (v) {
            setState(() {
              enabled = v;
              if (!v) reminderAt = null;
            });
            widget.onChanged(enabled, reminderAt);
          },
        ),

        if (enabled) ...[
          const SizedBox(height: 8),

          OutlinedButton.icon(
            icon: const Icon(Icons.alarm),
            onPressed: _pickDateTime,
            label: Text(
              reminderAt == null
                  ? "Select date & time"
                  : DateFormat.yMMMd().add_jm().format(reminderAt!),
            ),
          ),

          const SizedBox(height: 4),
          const Text(
            "You’ll get a reminder at selected time",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ],
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: reminderAt ?? DateTime.now(),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(reminderAt ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      error = null;
    });

    widget.onChanged(enabled, reminderAt);
  }
}
