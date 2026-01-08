import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_button.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: AppButton(
          text: 'Go to Tasks',
          onPressed: () {
            context.go(AppRoutes.tasks);
          },
        ),
      ),
    );
  }
}
