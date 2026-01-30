import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Use the database alias to match TaskList and TaskCreate screens
import '../../../data/database/database.dart' as db;
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/task_providers.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final db.Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  
  Color _getStatusColor(String status) {
    if (status == 'done') return Colors.green;
    if (status == 'inProgress') return Colors.orange;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.task.status ?? 'todo');
    final dateFormat = DateFormat('MMM dd, yyyy');

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
            child: BackButton(color: Colors.black87, onPressed: () => Navigator.pop(context)),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Visual Depth Blob
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: statusColor.withOpacity(0.08),
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
                      _buildStatusBadge(statusColor),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        widget.task.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1C1E),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Information Grid (Real Data)
                      _buildInfoSection(dateFormat),
                      
                      const SizedBox(height: 32),

                      // Assignee Section (New for Sprint 6)
                      if (widget.task.assigneeId != null) ...[
                        const Text("ASSIGNED TO", style: _sectionHeaderStyle),
                        const SizedBox(height: 12),
                        _buildAssigneeTile(),
                        const SizedBox(height: 32),
                      ],

                      // Description Section
                      const Text("DESCRIPTION", style: _sectionHeaderStyle),
                      const SizedBox(height: 12),
                      Text(
                        widget.task.description ?? "No additional details provided.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black.withOpacity(0.6),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              _buildBottomAction(statusColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        (widget.task.status ?? 'TODO').toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildInfoSection(DateFormat df) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoTile(Icons.calendar_month_rounded, "Due Date", 
              widget.task.dueDate != null ? df.format(widget.task.dueDate!) : "No Date"),
          _vDivider(),
          _infoTile(Icons.priority_high_rounded, "Priority", 
              _getPriorityText(widget.task.priority ?? 1)),
        ],
      ),
    );
  }

  Widget _buildAssigneeTile() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text("U${widget.task.assigneeId}", style: const TextStyle(color: AppColors.primary, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Text("Member ID: ${widget.task.assigneeId}", style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _getPriorityText(int p) {
    if (p == 3) return "High";
    if (p == 2) return "Medium";
    return "Low";
  }

  Widget _vDivider() => Container(height: 30, width: 1, color: Colors.grey.shade100);

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
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Logic to cycle status via ref.read(tasksProvider.notifier)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

const _sectionHeaderStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w800,
  color: Color(0xFF8E8E8E),
  letterSpacing: 1.5,
);