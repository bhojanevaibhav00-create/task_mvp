import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import 'package:task_mvp/core/routes/app_router.dart';
import 'package:task_mvp/core/constants/app_routes.dart';

/// 🔥 Stream notifier to refresh GoRouter on auth changes
class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,

  // 🔥 THIS IS THE MAGIC LINE
  refreshListenable: AuthRefreshNotifier(),

  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;

    final isLoggingIn = state.matchedLocation == AppRoutes.login;
    final isRegistering = state.matchedLocation == AppRoutes.register;

    // 🚫 If NOT logged in → force login
    if (user == null) {
      return (isLoggingIn || isRegistering)
          ? null
          : AppRoutes.login;
    }

    // ✅ If logged in → prevent going back to login/register
    if (isLoggingIn || isRegistering) {
      return AppRoutes.dashboard;
    }

    return null;
  },

  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
);
