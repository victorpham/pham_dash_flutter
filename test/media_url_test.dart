import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/config/app_config.dart';

void main() {
  group('mediaUrl', () {
    // No --dart-define in a test run, so this is the declared default.
    const origin = AppConfig.apiOrigin;

    test('prefixes the origin onto a root-relative path', () {
      expect(
        AppConfig.mediaUrl('/uploads/profiles/abc.png'),
        '$origin/uploads/profiles/abc.png',
      );
    });

    test('keeps the signature, which is the credential', () {
      // Dropping the query string turns every avatar into a 401.
      expect(
        AppConfig.mediaUrl('/uploads/profiles/abc.png?exp=123&sig=xyz'),
        '$origin/uploads/profiles/abc.png?exp=123&sig=xyz',
      );
    });

    test('re-hosts a legacy absolute URL, signature and all', () {
      expect(
        AppConfig.mediaUrl('http://localhost:5239/uploads/profiles/a.png?exp=1&sig=z'),
        '$origin/uploads/profiles/a.png?exp=1&sig=z',
      );
    });

    test('tolerates a path stored without its leading slash', () {
      expect(
        AppConfig.mediaUrl('uploads/profiles/abc.png'),
        '$origin/uploads/profiles/abc.png',
      );
    });

    test('drops the retired /profile-images/ shape rather than 401ing', () {
      // That route no longer exists and the server refuses to sign anything
      // outside /uploads/, so building a URL only buys a guaranteed 401.
      // Null makes PersonAvatar fall back to initials.
      expect(AppConfig.mediaUrl('/profile-images/person_88_abc.png'), isNull);
    });

    test('drops a legacy absolute URL that points outside /uploads/', () {
      expect(
        AppConfig.mediaUrl('http://localhost:5239/profile-images/person_88_abc.png'),
        isNull,
      );
    });

    test('null and empty stay null', () {
      expect(AppConfig.mediaUrl(null), isNull);
      expect(AppConfig.mediaUrl(''), isNull);
    });

    test('spelling audio resolves the same way', () {
      expect(
        AppConfig.mediaUrl('/uploads/spelling-audio/w.mp3?exp=1&sig=z'),
        '$origin/uploads/spelling-audio/w.mp3?exp=1&sig=z',
      );
    });
  });
}
