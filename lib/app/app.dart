import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import '../features/settings/settings_provider.dart';

/// Root application widget for TokSaver.
class TokSaverApp extends ConsumerWidget {
  const TokSaverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isAmoled = ref.watch(amoledDarkProvider);

    return MaterialApp.router(
      title: 'TokSaver',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.light,
      darkTheme: isAmoled ? AppTheme.amoled : AppTheme.dark,
      themeMode: themeMode,
      // Localization wired in later (Phase 1.5)
    );
  }
}

