import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:task_mvp/core/constants/app_colors.dart';
import '../domain/task_entity.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskEntity task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  // Color mapping based on status for dynamic UI
  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.done:
        return Colors.green;
      case TaskStatus.inProgress:
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  void _changeStatus() {
    setState(() {
      widget.task.status =
          TaskStatus.values[(widget.task.status.index + 1) % TaskStatus.values.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.task.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: BackButton(color: Colors.black87),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient Blobs for depth
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: statusColor.withOpacity(0.1),
            ),
          ),
          
          Column(
            children: [
              const SizedBox(height: 100),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          widget.task.status.name.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        widget.task.title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1C1E),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Information Grid
                      _buildInfoSection(),
                      
                      const SizedBox(height: 32),

                      // Description Section
                      const Text(
                        "DESCRIPTION",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No additional details provided for this task. You can edit the task to add more context and notes.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black.withOpacity(0.7),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom Action Bar
              _buildBottomAction(statusColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoTile(Icons.calendar_today_rounded, "Due Date", "Today"),
          Container(height: 30, width: 1, color: Colors.grey.shade200),
          _infoTile(Icons.priority_high_rounded, "Priority", "High"),
          Container(height: 30, width: 1, color: Colors.grey.shade200),
          _infoTile(Icons.category_rounded, "Category", "Work"),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBottomAction(Color statusColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _changeStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Update Progress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.edit_note_rounded, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}