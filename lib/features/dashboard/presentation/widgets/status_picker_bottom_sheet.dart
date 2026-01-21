import 'package:flutter/material.dart';
import '../../../../data/models/enums.dart';

Future<void> showStatusPickerBottomSheet({
  required BuildContext context,
  required TaskStatus currentStatus,
  required ValueChanged<TaskStatus> onSelected,
}) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Move task to",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _statusTile(
              context,
              label: "To Do",
              status: TaskStatus.todo,
              currentStatus: currentStatus,
              onSelected: onSelected,
            ),
            _statusTile(
              context,
              label: "In Progress",
              status: TaskStatus.inProgress,
              currentStatus: currentStatus,
              onSelected: onSelected,
            ),
            _statusTile(
              context,
              label: "Done",
              status: TaskStatus.done,
              currentStatus: currentStatus,
              onSelected: onSelected,
            ),
          ],
        ),
      );
    },
  );
}

Widget _statusTile(
    BuildContext context, {
      required String label,
      required TaskStatus status,
      required TaskStatus currentStatus,
      required ValueChanged<TaskStatus> onSelected,
    }) {
  final isSelected = status == currentStatus;

  return ListTile(
    title: Text(label),
    trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
    onTap: () {
      Navigator.pop(context);
      onSelected(status);
    },
  );
}
