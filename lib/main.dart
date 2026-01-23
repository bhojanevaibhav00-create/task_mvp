import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/task_providers.dart';

void main() {
  runApp(const ProviderScope(child: AppBootstrap()));
}

class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  @override
  void initState() {
    super.initState();

    /// 🔔 App start reminder init + permission + resync
    Future.microtask(() async {
      final reminder = ref.read(reminderServiceProvider);

      await reminder.init();
      await reminder.requestPermission();
      await reminder.resyncOnAppStart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MyApp();
  }
}
