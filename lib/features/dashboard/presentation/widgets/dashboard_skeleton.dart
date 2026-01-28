import 'package:flutter/material.dart';
import 'summary_card_skeleton.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: const [
              SummaryCardSkeleton(),
              SizedBox(width: 12),
              SummaryCardSkeleton(),
              SizedBox(width: 12),
              SummaryCardSkeleton(),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              itemCount: 6,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 12),
              itemBuilder: (_, __) => Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
