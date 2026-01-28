import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MembersListSkeleton extends StatelessWidget {
  const MembersListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (_, __) => ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.chipBackground,
        ),
        title: Container(
          height: 12,
          width: 120,
          color: AppColors.chipBackground,
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 6),
          height: 10,
          width: 80,
          color: AppColors.chipBackground,
        ),
      ),
    );
  }
}
