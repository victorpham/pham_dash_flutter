import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  final List<CacheEvent> _events = [];

  /// Newest first.
  List<CacheEvent> get events => List.unmodifiable(_events.reversed);

  void record(CacheEventKind kind, String key, {String? detail}) {
    final event = CacheEvent(kind, key, at: DateTime.now(), detail: detail);
    _events.add(event);
    if (_events.length > capacity) _events.removeAt(0);
    if (_echo) debugPrint('[cache] $event');
  }

  void clear() => _events.clear();
}

final cacheLogProvider = Provider<CacheLog>((ref) => CacheLog.instance);
