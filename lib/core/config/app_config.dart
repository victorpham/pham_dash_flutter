/// Build-time configuration, supplied with `--dart-define`.
class AppConfig {
  const AppConfig._();

  /// The API **server root**, deliberately without the `/api` segment.
  ///
  /// Uploaded media (`/uploads/profile-pictures/...`, `/uploads/spelling-audio/...`)
  /// is served as static files from this origin, not from under `/api`. Storing
  /// the origin and letting [ApiClient] append `/api` means [mediaUrl] is a
  /// plain concatenation, instead of the "strip the /api/ segment back off"
  /// dance the Kotlin app has to do.
  ///
  /// Defaults to the Android emulator's alias for the host loopback. On a
  /// physical device pass the host's LAN address instead:
  ///   flutter run --dart-define=API_ORIGIN=http://192.168.1.20:5100
  /// The iOS simulator shares the host's network, so it wants http://localhost:5100.
  static const String apiOrigin = String.fromEnvironment(
    'API_ORIGIN',
    defaultValue: 'http://10.0.2.2:5100',
  );

  /// Base URL for API calls — the origin plus the `/api` prefix.
  static String get apiBaseUrl => '$apiOrigin/api';

  /// Resolves a stored media path to an absolute URL.
  ///
  /// Paths are stored root-relative (`/uploads/...`), but legacy rows may hold a
  /// full absolute URL pointing at an old host and port. The web client handles
  /// that by keeping only `new URL(path).pathname` and re-prefixing; we do the
  /// same, so a stale `http://localhost:5239/uploads/x.jpg` still resolves
  /// against the current origin.
  ///
  /// These are plain GETs on the same origin. `UseStaticFiles()` runs before
  /// authentication in the API pipeline, so they need no bearer token.
  static String? mediaUrl(String? storedPath) {
    if (storedPath == null || storedPath.isEmpty) return null;

    var path = storedPath;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final parsed = Uri.tryParse(path);
      if (parsed == null) return null;
      path = parsed.path;
    }
    if (!path.startsWith('/')) path = '/$path';
    return '$apiOrigin$path';
  }
}
