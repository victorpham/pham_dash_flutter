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
  /// Media is no longer served anonymously: the API signs these paths and
  /// returns `/uploads/...?exp=&sig=`, and requests without a valid signature
  /// are refused. **The query string is the credential**, so it has to survive
  /// this method — dropping it turns every avatar into a 401.
  ///
  /// Returns null for a path outside [mediaPathPrefix]. Some rows still hold the
  /// retired `/profile-images/person_<id>_<guid>.png` shape; that route is gone
  /// and the server refuses to sign anything outside `/uploads/`, so building a
  /// URL for one only buys a guaranteed 401. Callers fall back to initials.
  /// Mirrors `MediaLink.Normalize` on the API.
  static String? mediaUrl(String? storedPath) {
    if (storedPath == null || storedPath.isEmpty) return null;

    var path = storedPath;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final parsed = Uri.tryParse(path);
      if (parsed == null) return null;
      // Path *and* query: `parsed.path` alone would strip the signature.
      path = parsed.hasQuery ? '${parsed.path}?${parsed.query}' : parsed.path;
    }
    if (!path.startsWith('/')) path = '/$path';
    if (!path.toLowerCase().startsWith(mediaPathPrefix)) return null;
    return '$apiOrigin$path';
  }

  /// URL prefix everything the API serves as media lives under, matching
  /// `MediaLink.PathPrefix`.
  static const String mediaPathPrefix = '/uploads/';
}
