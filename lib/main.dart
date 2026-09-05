import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loaded before the first frame so the cached accent colour and theme mode
  // are available synchronously — otherwise every cold start flashes the
  // default emerald before settling on the user's colour.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const PhamDashApp(),
    ),
  );
}

class PhamDashApp extends ConsumerStatefulWidget {
  const PhamDashApp({super.key});

  @override
  ConsumerState<PhamDashApp> createState() => _PhamDashAppState();
}

class _PhamDashAppState extends ConsumerState<PhamDashApp> {
  @override
  void initState() {
    super.initState();
    // Restoring the session is what decides whether the first route is the
    // dashboard or the login screen, so kick it off immediately.
    ref.read(authControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeControllerProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PhamDash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(theme.seed),
      darkTheme: AppTheme.dark(theme.seed),
      themeMode: theme.mode,
      routerConfig: router,
    );
  }
}
