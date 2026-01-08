import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';

class KanbanBoardSkeleton extends StatelessWidget {
  const KanbanBoardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: const [
          _KanbanColumn(title: "Todo"),
          _KanbanColumn(title: "In Progress"),
          _KanbanColumn(title: "Done"),
        ],
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;

  const _KanbanColumn({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: 12),
          _PlaceholderCard(),
          _PlaceholderCard(),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
