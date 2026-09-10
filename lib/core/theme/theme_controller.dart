import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'app_theme.dart';

class ThemeSettings {
  const ThemeSettings({required this.seed, required this.mode});

  final Color seed;
  final ThemeMode mode;

  ThemeSettings copyWith({Color? seed, ThemeMode? mode}) =>
      ThemeSettings(seed: seed ?? this.seed, mode: mode ?? this.mode);
}

/// Accent colour and light/dark mode.
///
/// Resolution order for the accent: the user's saved `primaryColor` from the
/// API, then the value cached locally from the last run, then the emerald
/// default. Caching matters because the API call needs a signed-in session, so
/// on a cold start the first frame would otherwise always be the default.
///
/// The MVP **never writes preferences back**. `PUT /api/user-preferences` is a
/// full replace that nulls every omitted field, so a partial write from the
/// phone would silently wipe the web app's saved theme. The dark-mode switch in
/// the drawer footer is therefore a device-local setting.
class ThemeController extends Notifier<ThemeSettings> {
  static const _seedKey = 'phamdash_primary_color';
  static const _modeKey = 'phamdash_theme_mode';

  @override
  ThemeSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final cachedSeed = parseHexColor(prefs.getString(_seedKey));
    final cachedMode = _modeFromName(prefs.getString(_modeKey));

    return ThemeSettings(
      seed: cachedSeed ?? kDefaultPrimary,
      mode: cachedMode ?? ThemeMode.system,
    );
  }

  /// Pulls the saved theme from the API. Safe to call on every sign-in.
  ///
  /// Failure is deliberately silent: the theme is cosmetic, and a user whose
  /// preferences request fails should still get a usable app on the cached or
  /// default accent.
  Future<void> loadFromApi() async {
    try {
      final prefs = await ref.read(userPreferenceRepositoryProvider).get();

      final seed = parseHexColor(prefs.primaryColor);
      if (seed != null) {
        state = state.copyWith(seed: seed);
        await ref
            .read(sharedPreferencesProvider)
            .setString(_seedKey, prefs.primaryColor!);
      }

      // Only honour the server's darkMode when the user has not chosen a mode
      // on this device; a local choice is more specific and should win.
      final localMode =
          ref.read(sharedPreferencesProvider).getString(_modeKey);
      if (localMode == null && prefs.darkMode != null) {
        state = state.copyWith(
          mode: prefs.darkMode! ? ThemeMode.dark : ThemeMode.light,
        );
      }
    } catch (_) {
      // Keep whatever the cache gave us.
    }
  }

  /// The drawer footer's dark-mode switch. Persists to this device only.
  Future<void> toggleDarkMode(Brightness current) async {
    final next =
        current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    state = state.copyWith(mode: next);
    await ref.read(sharedPreferencesProvider).setString(_modeKey, next.name);
  }

  static ThemeMode? _modeFromName(String? name) => switch (name) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => null,
      };
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeSettings>(ThemeController.new);
