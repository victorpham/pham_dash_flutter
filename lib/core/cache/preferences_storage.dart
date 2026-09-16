import 'dart:convert';

import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Riverpod's offline-persistence [Storage], kept in `SharedPreferences`.
///
/// This is what lets a tab render its last-loaded list on the first frame of
/// a cold launch while the real fetch - and, after an hour idle, the database
/// resume behind it - runs in the background. See `CachedList`.
///
/// `SharedPreferences` rather than `riverpod_sqflite` or a file: it is already
/// loaded before the first frame (`main()` awaits it so the theme can read it
/// synchronously), and a synchronous [read] is what makes the cached list
/// available on that first frame instead of one frame later. The payloads are
/// family-sized - the people directory, the largest, is on the order of 100 KB.
/// If that ever grows into megabytes, a file per key is the upgrade path.
///
/// **[delete] deliberately keeps unexpired entries.** Riverpod calls it in three
/// cases: an entry expired on read, a `destroyKey` changed (unused here), and
/// *the provider errored*. The third is the wrong call for this app - the
/// failure seen most is the database wake outrunning the request timeout, and
/// the saved copy is exactly what the next launch should show over the
/// "couldn't refresh" banner - so this store honours expiry itself and declines
/// the rest.
final class PreferencesStorage extends Storage<String, String> {
  PreferencesStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _prefix = 'phamdash_cache:';

  Iterable<String> get _keys =>
      _prefs.getKeys().where((k) => k.startsWith(_prefix));

  _Entry? _entry(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      return _Entry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Not an envelope this version wrote; drop it rather than keep failing
      // on it every launch.
      _prefs.remove('$_prefix$key');
      return null;
    }
  }

  @override
  PersistedData<String>? read(String key) {
    final entry = _entry(key);
    if (entry == null) return null;
    return PersistedData(entry.data, expireAt: entry.expireAt);
  }

  @override
  Future<void> write(String key, String value, StorageOptions options) {
    final entry = _Entry(
      value,
      expireAt: switch (options.cacheTime.duration) {
        null => null,
        final duration => DateTime.now().toUtc().add(duration),
      },
    );
    return _prefs.setString('$_prefix$key', jsonEncode(entry.toJson()));
  }

  @override
  Future<void> delete(String key) async {
    final entry = _entry(key);
    if (entry != null && entry.isExpired) {
      await _prefs.remove('$_prefix$key');
    }
  }

  @override
  void deleteOutOfDate() {
    for (final prefixed in _keys.toList()) {
      final key = prefixed.substring(_prefix.length);
      final entry = _entry(key);
      if (entry != null && entry.isExpired) _prefs.remove(prefixed);
    }
  }

  /// Drops every cached list. Called on sign-out, because todo lists are
  /// per-user and the next person to sign in on this phone must not see them.
  ///
  /// Static, on the raw preferences: the provider is typed as the abstract
  /// [Storage] so tests can swap in `Storage.inMemory()`, and sign-out should
  /// not have to sniff which one it got.
  static Future<void> clearAll(SharedPreferences prefs) async {
    for (final key in prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      await prefs.remove(key);
    }
  }
}

class _Entry {
  const _Entry(this.data, {this.expireAt});

  factory _Entry.fromJson(Map<String, dynamic> json) => _Entry(
        json['data'] as String,
        expireAt: switch (json['expireAt']) {
          final String iso => DateTime.parse(iso),
          _ => null,
        },
      );

  final String data;
  final DateTime? expireAt;

  bool get isExpired {
    final at = expireAt;
    return at != null && !at.isAfter(DateTime.now().toUtc());
  }

  Map<String, dynamic> toJson() => {
        'data': data,
        'expireAt': expireAt?.toIso8601String(),
      };
}
