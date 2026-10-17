import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What happened to one cached list, recorded so the phone can say so later.
///
/// Every way the offline cache can fail to seed a screen is silent by
/// construction. Riverpod swallows a `decode` throw into its container's error
/// handler and leaves a valueless `AsyncLoading`; `PreferencesStorage` drops an
/// envelope it cannot parse; a sign-out clears the lot without a word. The
/// result is a tab that opens to a spinner with no way to tell a cold cache
/// from a corrupt one from a wipe. This is the missing record.
enum CacheEventKind {
  /// The stored copy was read and seeded the provider.
  hit,

  /// Nothing was stored under the key.
  miss,

  /// Something was stored but had passed its expiry.
  expired,

  /// The stored value was not an envelope this version wrote, so it was
  /// dropped - see `PreferencesStorage._entry`.
  envelopeCorrupt,

  /// The envelope decoded but its payload did not, so no seed happened.
  decodeFailed,

  /// The payload decoded with some rows skipped - see [tolerantDecodeList].
  rowsSkipped,

  /// `persistList` was never called on this build, so the store was not read.
  notSeeded,

  /// Every cached key was dropped.
  cleared,

  /// A 401 survived its retry and the session ended.
  sessionExpired,

  /// An error Riverpod handed to the zone rather than to a provider - which is
  /// where a `persist` decode failure goes. See `main()`.
  uncaught,

  /// An interactive sign-in finished. The detail says whether the IdP issued
  /// a refresh token - without one the session cannot outlive the ID token.
  authSignIn,

  /// A stored session was loaded at launch.
  authRestore,

  /// The ID token was renewed with the refresh token.
  authRefresh,

  /// A renewal did not produce a token, and why - including the IdP's
  /// `error_description`, which is where Entra puts its AADSTS code.
  authRefreshFailed,

  /// The user signed out from the menu, as opposed to [sessionExpired].
  authSignOut;

  /// Auth events are also kept across launches - see
  /// [CacheLog.keepAuthHistoryIn].
  bool get isAuth => switch (this) {
    authSignIn ||
    authRestore ||
    authRefresh ||
    authRefreshFailed ||
    authSignOut ||
    sessionExpired => true,
    _ => false,
  };
}

@immutable
class CacheEvent {
  const CacheEvent(this.kind, this.key, {required this.at, this.detail});

  final CacheEventKind kind;

  /// The cache key, or - for [CacheEventKind.cleared] and
  /// [CacheEventKind.sessionExpired], which are not about one key - `'*'`.
  final String key;

  final DateTime at;

  /// A count, a reason, or the error that was thrown.
  final String? detail;

  @override
  String toString() {
    final name = kind.name;
    return detail == null ? '$key: $name' : '$key: $name ($detail)';
  }
}

/// A bounded, in-memory record of [CacheEvent]s.
///
/// In memory only and never written anywhere: it exists to be read on the
/// device right after something looked wrong, not to build a history. Nothing
/// here leaves the phone, and the payloads themselves are never recorded - only
/// their key, size and outcome.
class CacheLog {
  /// The shared instance. `PreferencesStorage` is constructed from a bare
  /// `SharedPreferences` and its sign-out helpers are static, so there is no
  /// `Ref` to thread a log through; tests get isolation from [clear] and from
  /// overriding [cacheLogProvider].
  static final CacheLog instance = CacheLog();

  /// Enough to cover a launch and the tabs opened just after it.
  static const int capacity = 50;

  /// Mirror each event to the console, so `flutter run` shows it as it
  /// happens. Off under `flutter test`, where every widget test that mounts a
  /// cached provider would otherwise bury the failures in cache chatter.
  static final bool _echo =
      kDebugMode && !Platform.environment.containsKey('FLUTTER_TEST');

  /// Where [authHistory] survives a restart. Deliberately outside the
  /// `phamdash_cache:` prefix, so neither sign-out nor `claimFor` clears it:
  /// the record of why a session ended has to outlive the session.
  static const String authHistoryKey = 'phamdash_auth_history';

  /// Enough to span a few days of launches and hourly refreshes.
  static const int authCapacity = 30;

  final List<CacheEvent> _events = [];
  final List<CacheEvent> _authHistory = [];
  SharedPreferences? _prefs;

  /// Newest first.
  List<CacheEvent> get events => List.unmodifiable(_events.reversed);

  /// Auth events from this launch and earlier ones, newest first.
  ///
  /// The session log alone cannot answer "why was I signed out overnight":
  /// the launch that saw the refresh fail is gone by the time anyone looks.
  /// Only outcomes are kept - never a token.
  List<CacheEvent> get authHistory => List.unmodifiable(_authHistory.reversed);

  /// Loads the stored auth history and keeps it up to date from now on. Call
  /// once at startup, before the session is restored.
  void keepAuthHistoryIn(SharedPreferences prefs) {
    _prefs = prefs;
    _authHistory
      ..clear()
      ..addAll(_readHistory(prefs.getString(authHistoryKey)));
  }

  void record(CacheEventKind kind, String key, {String? detail}) {
    final event = CacheEvent(kind, key, at: DateTime.now(), detail: detail);
    _events.add(event);
    if (_events.length > capacity) _events.removeAt(0);
    if (kind.isAuth) _recordAuth(event);
    if (_echo) debugPrint('[cache] $event');
  }

  void _recordAuth(CacheEvent event) {
    _authHistory.add(event);
    if (_authHistory.length > authCapacity) _authHistory.removeAt(0);
    final prefs = _prefs;
    if (prefs == null) return;
    unawaited(
      prefs.setString(
        authHistoryKey,
        jsonEncode([
          for (final e in _authHistory)
            {
              'kind': e.kind.name,
              'key': e.key,
              'at': e.at.toUtc().toIso8601String(),
              if (e.detail != null) 'detail': e.detail,
            },
        ]),
      ),
    );
  }

  /// Tolerant: a row this version cannot read is skipped, and an unreadable
  /// list is treated as empty - diagnostics must never break a launch.
  static List<CacheEvent> _readHistory(String? raw) {
    if (raw == null) return const [];
    try {
      final rows = jsonDecode(raw);
      if (rows is! List) return const [];
      return [
        for (final row in rows)
          if (row is Map<String, dynamic>)
            if (CacheEventKind.values.asNameMap()[row['kind']] case final kind?)
              if (DateTime.tryParse('${row['at']}') case final at?)
                CacheEvent(
                  kind,
                  '${row['key'] ?? '*'}',
                  at: at.toLocal(),
                  detail: row['detail'] as String?,
                ),
      ];
    } on Object {
      return const [];
    }
  }

  /// Empties this launch's log. The stored auth history is left alone.
  void clear() {
    _events.clear();
    _authHistory.clear();
  }
}

final cacheLogProvider = Provider<CacheLog>((ref) => CacheLog.instance);
