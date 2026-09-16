import 'package:flutter/material.dart';

/// The emerald the Vue app defaults to (`#10b981`) and the Kotlin app hardcodes
/// as `Emerald500`. Used when the user has no saved `primaryColor`.
const Color kDefaultPrimary = Color(0xFF10B981);

/// Parses a `#RRGGBB` (or `#AARRGGBB`) hex string from the API.
///
/// Category colours, list colours and `primaryColor` all arrive this way. The
/// API validates category colours against `^#[0-9A-Fa-f]{6}$` but list colours
/// are unvalidated, so this has to tolerate junk.
/// The eight swatches offered for list colours, people tags and todo labels.
///
/// The CSS named colours, so "Red" is the red anyone means by red. This
/// **diverges from the web editor**, which offers the Tailwind 100-level
/// pastels these used to mirror (`#fee2e2` and friends). Those read as washed
/// out here: the web paints a whole card background with them, while this
/// client uses the colour as a 4px stripe, a 35%-alpha app bar tint and small
/// chips, all of which need the saturation to register at all. Colours already
/// stored by the web keep working — nothing migrates, and `parseHexColor`
/// takes any hex.
///
/// Saturated backgrounds do mean text drawn on one needs a deliberate
/// foreground; see [onColor].
///
/// Lives here rather than in the todo feature that first needed it, because
/// people tags pick from the same palette and reaching across features for a
/// constant — worse, into a *screen* — is not worth saving a file.
const List<({String name, String? value})> kListColors = [
  (name: 'None', value: null),
  (name: 'Red', value: '#ff0000'),
  (name: 'Orange', value: '#ff8c00'),
  (name: 'Yellow', value: '#ffd700'),
  (name: 'Green', value: '#008000'),
  (name: 'Blue', value: '#0000ff'),
  (name: 'Purple', value: '#800080'),
  (name: 'Pink', value: '#ff1493'),
];

/// Black or white, whichever is legible on [background].
///
/// Needed because a label's colour is picked by the user and drawn *behind
/// text*: the theme's own `onSurface` is right for one end of the palette and
/// invisible at the other — white on gold, black on navy. Defers to
/// [ThemeData.estimateBrightnessForColor] rather than hand-rolling the
/// luminance threshold, so it stays consistent with how Material picks
/// foregrounds everywhere else.
///
/// `black87` rather than pure black, matching Material's own on-light colour.
Color onColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black87;

/// The label style for a chip tinted with a user-picked [background].
///
/// Null — meaning "leave it to the theme" — when there is no custom colour, and
/// also while [selected]: a selected chip is painted with `selectedColor`
/// rather than `backgroundColor`, so forcing a foreground for a background
/// Material is not using would be the one case that reads wrong.
TextStyle? chipLabelStyleOn(Color? background, {required bool selected}) =>
    background == null || selected
        ? null
        : TextStyle(color: onColor(background));

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
