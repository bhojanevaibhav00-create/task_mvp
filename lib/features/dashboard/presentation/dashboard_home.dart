import 'package:flutter/material.dart';
import 'package:task_mvp/core/constants/app_colors.dart';

class DashboardHome extends StatelessWidget {
  final String searchQuery;

  const DashboardHome({super.key, this.searchQuery = ""});

  // Sample tasks list
  final List<String> allTasks = const [
    "Buy groceries",
    "Complete project",
    "Call mom",
    "Read book",
    "Workout",
    "Check emails",
  ];

  @override
  Widget build(BuildContext context) {
    // Filter tasks based on search query
    final filteredTasks = allTasks
        .where((task) => task.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    if (filteredTasks.isEmpty) {
      return _buildEmptySearchState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredTasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildTaskCard(filteredTasks[index]);
      },
    );
  }

  Widget _buildTaskCard(String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {}, // Action for task selection
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Custom Icon Container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // Task Text
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1C1E),
                    ),
                  ),
                ),
                // Arrow indicator
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            "No tasks match your search",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try a different keyword",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}