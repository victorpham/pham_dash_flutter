import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'core/cache/cache_log.dart';
import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

/// Wrapped in a guarded zone so Riverpod's swallowed errors land somewhere.
///
/// `persist` catches anything its `decode` throws and passes it to the
/// container's `defaultOnError` - the right call, since a bad cached copy must
/// not break a screen, but `defaultOnError` forwards to
/// `Zone.current.handleUncaughtError` and `ProviderScope` exposes no hook to
/// intercept it. Without a zone of our own, the one error that explains a tab
/// opening to a bare spinner is written to a console nobody is attached to.
/// `ensureInitialized` has to happen inside the same zone as [runApp].
Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Loaded before the first frame so the cached accent colour and theme mode
    // are available synchronously — otherwise every cold start flashes the
    // default emerald before settling on the user's colour.
    final prefs = await SharedPreferences.getInstance();
    // Before the first frame, which is when the session is restored and the
    // first auth event recorded.
    CacheLog.instance.keepAuthHistoryIn(prefs);

    runApp(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const PhamDashApp(),
      ),
    );
  }, (error, stack) {
    CacheLog.instance.record(CacheEventKind.uncaught, '*', detail: '$error');
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
  });
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
