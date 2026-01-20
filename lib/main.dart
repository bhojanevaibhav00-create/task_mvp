import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'package:task_mvp/core/providers/task_providers.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AppBootstrap(),
    ),
  );
}

/// Bootstrap widget to run app-start logic
class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;

      // ✅ SAFE app-start resync
      Future.microtask(() {
        ref.read(reminderServiceProvider).resyncOnAppStart();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MyApp();
  }
}
