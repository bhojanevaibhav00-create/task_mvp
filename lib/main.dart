import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'package:task_mvp/core/providers/task_providers.dart';
import 'package:task_mvp/features/tasks/presentation/widgets/reminder_section.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AppBootstrap(),
    ),
  );
}

class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  bool initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!initialized) {
      initialized = true;
      Future.microtask(() async {
        final reminder = ref.read(reminderServiceProvider);
        await reminder.init();
        await reminder.requestPermission();
      });
    }
  }

  @override
  Widget build(BuildContext context) => const MyApp();
}
