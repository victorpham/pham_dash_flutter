import 'dart:convert';

/// Minimal JWT payload reader.
///
/// We only ever read claims out of a token we were just handed by the identity
/// provider over TLS; signature verification is the API's job, so this does not
/// attempt it and must not be used to make trust decisions.
class Jwt {
  const Jwt._();

  static Map<String, dynamic> claims(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return const {};
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      return json is Map<String, dynamic> ? json : const {};
    } catch (_) {
      return const {};
    }
  }

  static DateTime? expiry(String token) {
    final exp = claims(token)['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
  }

  /// The user id every user-scoped row in the API is keyed on.
  ///
  /// `UserContextService` reads `oid`, falling back to `nameidentifier` and then
  /// `sub`. We mirror that order so the id shown in the app matches the id the
  /// server filters by.
  static String? userId(String token) {
    final c = claims(token);
    for (final key in const [
      'oid',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
      'sub',
    ]) {
      final value = c[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  static String? displayName(String token) {
    final c = claims(token);
    for (final key in const ['name', 'given_name', 'preferred_username']) {
      final value = c[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  static String? email(String token) {
    final c = claims(token);
    for (final key in const ['email', 'preferred_username', 'upn']) {
      final value = c[key];
      if (value is String && value.contains('@')) return value;
    }
    return null;
  }
}
