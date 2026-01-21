import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/enums.dart';
import 'task_tile.dart';
import 'package:task_mvp/data/models/enums.dart';

class BoardColumn extends StatelessWidget {
  final String title;
  final List<Task> tasks;

  const BoardColumn({super.key, required this.title, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...tasks.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TaskTile(task: t),
          )),
        ],
      ),
    );
  }
}
