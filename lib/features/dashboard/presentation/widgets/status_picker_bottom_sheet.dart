import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Function to show a premium bottom sheet for task status selection.
/// Backend uses String values: 'todo', 'inProgress', 'done', 'review'.
Future<void> showStatusPickerBottomSheet({
  required BuildContext context,
  required String currentStatus, // 🚀 Changed to String for DB sync
  required ValueChanged<String> onSelected,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Center Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Text(
              "Update Status",
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF1E293B)
              ),
            ),
            const SizedBox(height: 16),

            // Mapping database strings to UI labels
            _statusTile(context, "To Do", "todo", currentStatus, onSelected),
            _statusTile(context, "In Progress", "inProgress", currentStatus, onSelected),
            _statusTile(context, "Under Review", "review", currentStatus, onSelected),
            _statusTile(context, "Completed", "done", currentStatus, onSelected),
            
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

Widget _statusTile(
  BuildContext context,
  String label,
  String statusValue,
  String currentStatus,
  ValueChanged<String> onSelected,
) {
  final isSelected = statusValue == currentStatus;

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppColors.primary : const Color(0xFF475569),
        ),
      ),
      trailing: isSelected 
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) 
          : null,
      onTap: () {
        Navigator.pop(context);
        onSelected(statusValue);
      },
    ),
  );
}