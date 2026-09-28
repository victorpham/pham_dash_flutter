import 'dart:convert';

import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cache_log.dart';

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
  PreferencesStorage(this._prefs, {CacheLog? log})
      : _log = log ?? CacheLog.instance;

  final SharedPreferences _prefs;
  final CacheLog _log;

  static const String _prefix = 'phamdash_cache:';

  /// The list ids the user has put into shopping-list order - see
  /// `ShoppingSortedLists` in the todo feature. Not a cache entry (it has no
  /// expiry and is never written by Riverpod), but it names lists that belong
  /// to the signed-in account, so [clearAll] drops it along with them.
  static const String shoppingSortKey = 'phamdash_shopping_sorted_lists';

  /// Whose cache this is. Also not a cache entry, but it is what scopes the
  /// ones that are - see [claimFor].
  static const String ownerKey = 'phamdash_cache_owner';

  Iterable<String> get _keys =>
      _prefs.getKeys().where((k) => k.startsWith(_prefix));

  _Entry? _entry(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      return _Entry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object catch (error) {
      // Not an envelope this version wrote; drop it rather than keep failing
      // on it every launch.
      _prefs.remove('$_prefix$key');
      _log.record(CacheEventKind.envelopeCorrupt, key, detail: '$error');
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

  /// Drops every cached list, and the per-list sort choices keyed on them.
  ///
  /// Called when the cache changes hands: an explicit sign-out, or a sign-in as
  /// a different account (see [claimFor]). **Not** on a forced session expiry -
  /// that is almost always the same user whose token lapsed, and wiping their
  /// offline copy at the exact moment the network is unreliable is the wrong
  /// trade. [claimFor] is what keeps the per-user guarantee instead.
  ///
  /// Static, on the raw preferences: the provider is typed as the abstract
  /// [Storage] so tests can swap in `Storage.inMemory()`, and sign-out should
  /// not have to sniff which one it got.
  static Future<void> clearAll(
    SharedPreferences prefs, {
    String reason = 'sign-out',
    CacheLog? log,
  }) async {
    for (final key in prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      await prefs.remove(key);
    }
    await prefs.remove(shoppingSortKey);
    await prefs.remove(ownerKey);
    (log ?? CacheLog.instance)
        .record(CacheEventKind.cleared, '*', detail: reason);
  }

  /// Records [userId] as the cache's owner, clearing it first if it belonged to
  /// somebody else.
  ///
  /// This is the per-user guarantee that [clearAll]-on-every-sign-out used to
  /// provide: todo lists are per-user, so the next person to sign in on this
  /// phone must not open to the last one's. Doing it on sign-*in* rather than
  /// sign-out means a session that merely expired keeps its saved copy, which
  /// is the whole point of having one.
  ///
  /// A fresh install has no owner and keeps whatever is there (nothing).
  static Future<void> claimFor(
    SharedPreferences prefs,
    String userId, {
    CacheLog? log,
  }) async {
    final owner = prefs.getString(ownerKey);
    if (owner == userId) return;
    if (owner != null) {
      await clearAll(prefs, reason: 'owner-changed', log: log);
    }
    await prefs.setString(ownerKey, userId);
  }

  /// Every cached key with its size and expiry, for the diagnostics screen.
  /// Static and on the raw preferences for the same reason [clearAll] is.
  static List<CacheEntryInfo> describeAll(SharedPreferences prefs) {
    final store = PreferencesStorage(prefs);
    return [
      for (final prefixed
          in prefs.getKeys().where((k) => k.startsWith(_prefix)).toList())
        if (store._entry(prefixed.substring(_prefix.length)) case final entry?)
          CacheEntryInfo(
            key: prefixed.substring(_prefix.length),
            bytes: entry.data.length,
            expireAt: entry.expireAt,
          ),
    ]..sort((a, b) => a.key.compareTo(b.key));
  }
}

/// One stored key as the diagnostics screen shows it.
class CacheEntryInfo {
  const CacheEntryInfo({
    required this.key,
    required this.bytes,
    required this.expireAt,
  });

  final String key;
  final int bytes;
  final DateTime? expireAt;
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
