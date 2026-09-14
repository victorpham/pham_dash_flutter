import 'package:flutter/material.dart';

/// The emerald the Vue app defaults to (`#10b981`) and the Kotlin app hardcodes
/// as `Emerald500`. Used when the user has no saved `primaryColor`.
const Color kDefaultPrimary = Color(0xFF10B981);

/// Parses a `#RRGGBB` (or `#AARRGGBB`) hex string from the API.
///
/// Category colours, list colours and `primaryColor` all arrive this way. The
/// API validates category colours against `^#[0-9A-Fa-f]{6}$` but list colours
/// are unvalidated, so this has to tolerate junk.
/// The eight swatches the web editor offers, in its order. Pastels, because a
/// list's colour is a background wash on the web card rather than an accent.
///
/// Lives here rather than in the todo feature that first needed it, because
/// people tags pick from the same palette and reaching across features for a
/// constant — worse, into a *screen* — is not worth saving a file.
const List<({String name, String? value})> kListColors = [
  (name: 'None', value: null),
  (name: 'Red', value: '#fee2e2'),
  (name: 'Orange', value: '#ffedd5'),
  (name: 'Yellow', value: '#fef9c3'),
  (name: 'Green', value: '#dcfce7'),
  (name: 'Blue', value: '#dbeafe'),
  (name: 'Purple', value: '#e9d5ff'),
  (name: 'Pink', value: '#fce7f3'),
];

Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  var value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? null : Color(parsed);
}

/// Builds the app theme from the user's saved accent colour.
///
/// The web client hand-rolls a hex -> HSL -> 50..950 PrimeVue palette to do
/// this. Material's [ColorScheme.fromSeed] covers the same ground, so only the
/// seed carries over; `themePreset` and `surfaceColor` are PrimeVue concepts
/// with no Material equivalent and are ignored, as the mobile web layout
/// effectively does too.
class AppTheme {
  const AppTheme._();

  static ThemeData light(Color seed) => _build(seed, Brightness.light);

  static ThemeData dark(Color seed) => _build(seed, Brightness.dark);

  static ThemeData _build(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        height: 62,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        indicatorColor: scheme.primaryContainer.withValues(alpha: 0.7),
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: scheme.outlineVariant.withValues(alpha: 0.5),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        backgroundColor: scheme.surfaceContainerHighest,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    );
  }
}

/// Surface tints used by the widgets, derived from the scheme so they track
/// light and dark automatically.
extension AppColors on ColorScheme {
  /// The subtle card background used for event rows and list cards.
  Color get rowSurface => surfaceContainerHighest.withValues(alpha: 0.45);

  /// A muted foreground for secondary text — times, counts, relative dates.
  Color get mutedForeground => onSurfaceVariant;

  /// The colour a completed checklist item turns.
  Color get completed =>
      brightness == Brightness.dark
          ? const Color(0xFF4ADE80)
          : const Color(0xFF16A34A);
}
