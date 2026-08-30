import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';
import 'state/providers.dart';
import 'theme/app_theme.dart';

/// Root widget.
///
/// Deliberately does not wrap the app in a `MediaQuery` that clamps
/// `textScaler`: whatever text size the user has chosen in their phone's
/// settings is the size they need, and every screen is built to grow.
class CivicsTestApp extends ConsumerStatefulWidget {
  const CivicsTestApp({super.key});

  @override
  ConsumerState<CivicsTestApp> createState() => _CivicsTestAppState();
}

class _CivicsTestAppState extends ConsumerState<CivicsTestApp> {
  @override
  void initState() {
    super.initState();
    // Optional, non-blocking: try for fresher answers to the four questions
    // that change. Failure is silent and the app is already fully usable.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(remoteConfigProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'US Citizenship Test 2025',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}
