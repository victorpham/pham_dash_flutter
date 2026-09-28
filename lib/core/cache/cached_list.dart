import 'dart:convert';

import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/decode.dart';
import '../providers.dart';
import 'cache_log.dart';
import 'freshness.dart';

/// Stale-while-revalidate for a list provider.
///
/// A notifier that mixes this in and calls [persistList] first thing in
/// `build()` gets, on a cold launch, its last successful result as the initial
/// state - an `AsyncLoading` that already carries a value, so `AsyncView`
/// renders the list at once and shows the refresh as a thin bar over it. The
/// fetch that `build()` goes on to return replaces it, and is written back for
/// next time. `provider.future` still waits for the fetch, so pull-to-refresh
/// and every `ref.invalidate` site behave exactly as before.
///
/// This is Riverpod's own offline-persistence, from its `experimental` export.
/// The hand-rolled alternative cannot build a loading-with-value state from
/// public API, and that state is what lets the UI tell "cached, refreshing"
/// from "loaded"; the experimental import is the smaller risk. If a riverpod
/// upgrade renames `persist`, this file is the only place to follow it.
///
/// **The store is read once, at the element's first build.** Riverpod guards
/// its read with `ref.isFirstBuild`, so an `invalidate`, a `refresh` or a
/// dependency change re-runs `build()` without looking at the cache again -
/// what keeps data on screen after that is Riverpod's in-memory
/// `copyWithPrevious`, not this. A screen that needs the saved copy on a build
/// that is not the first one wants [cachedSeedOf] and `AsyncView.fallback`.
///
/// Storage is [PreferencesStorage]; a failed refresh keeps the saved copy on
/// purpose - see there.
mixin CachedList<T> on AsyncNotifier<List<T>> {
  /// Long enough that a phone left in a drawer still opens to its lists; short
  /// enough that a provider removed from the app does not leave its data
  /// behind forever.
  static const StorageCacheTime cacheTime = StorageCacheTime(
    Duration(days: 30),
  );

  /// Seeds the state from [key] on the notifier's first build and writes every
  /// later `AsyncData` back. [trim] is applied to the cached list only - the
  /// schedule uses it to drop events that ended before today.
  ///
  /// Skip the call, rather than vary the key, when the current build is not
  /// the launch view (a filtered todo list): the write-back listener is
  /// re-registered per build, so a build without this call writes nothing.
  /// Record [CacheEventKind.notSeeded] when you do, or the skip is invisible.
  void persistList(
    String key, {
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    List<T> Function(List<T>)? trim,
  }) {
    final storage = ref.watch(cacheStorageProvider);
    final log = ref.watch(cacheLogProvider);

    // Only a first build will look at the store, so only a first build has an
    // outcome worth recording. `hit` is left to the decode below, which is the
    // one that knows whether the payload survived.
    if (ref.isFirstBuild) _recordSeedLookup(storage, log, key);

    persist(
      storage,
      key: key,
      encode: (items) => encodeList(items, toJson),
      decode: (encoded) {
        final items = tolerantDecodeList(encoded, fromJson, key: key, log: log);
        return trim == null ? items : trim(items);
      },
      options: const StorageOptions(cacheTime: cacheTime),
    );
    listenSelf((previous, next) => recordFetch(ref, key, previous, next));
  }
}

void _recordSeedLookup(
  Storage<String, String> storage,
  CacheLog log,
  String key,
) {
  final entry = _readSync(storage, key);
  if (entry == null) {
    log.record(CacheEventKind.miss, key);
    return;
  }
  if (_isExpired(entry)) log.record(CacheEventKind.expired, key);
}

/// The stored entry, or null if there is none or the store answers
/// asynchronously. Both stores this app uses answer synchronously - see
/// `PreferencesStorage` - and an async one simply reports nothing.
PersistedData<String>? _readSync(Storage<String, String> storage, String key) {
  final read = storage.read(key);
  return read is Future<PersistedData<String>?> ? null : read;
}

bool _isExpired(PersistedData<String> entry) {
  final at = entry.expireAt;
  return at != null && at.isBefore(DateTime.now());
}

/// The stored form: a JSON array of each item's wire shape, so the same
/// `fromJson` that reads the API reads the cache.
String encodeList<T>(List<T> items, Map<String, dynamic> Function(T) toJson) =>
    jsonEncode([for (final item in items) toJson(item)]);

List<T> decodeEncodedList<T>(
  String encoded,
  T Function(Map<String, dynamic>) fromJson,
) => decodeList(jsonDecode(encoded), fromJson);

/// [decodeEncodedList], but one unreadable row does not cost the whole list.
///
/// The cache and the API need different tempers here. `decodeList` is strict on
/// purpose: a row the API sends that this app cannot read is a bug worth
/// surfacing. A row in the *cache* that this app cannot read usually means the
/// model gained a field since the copy was written, and dropping the launch
/// view of an entire tab over one stale row is a bad trade - the fetch behind
/// it is about to replace them all anyway.
///
/// Throws when nothing at all is usable, rather than returning an empty list:
/// Riverpod catches that and leaves the provider unseeded, whereas an empty
/// list would seed "nothing here yet" over data that does exist.
List<T> tolerantDecodeList<T>(
  String encoded,
  T Function(Map<String, dynamic>) fromJson, {
  required String key,
  CacheLog? log,
}) {
  final decoded = jsonDecode(encoded);
  if (decoded is! List) {
    log?.record(
      CacheEventKind.decodeFailed,
      key,
      detail: 'payload is not a JSON array',
    );
    throw FormatException('Cached "$key" is not a JSON array');
  }

  final items = <T>[];
  var skipped = 0;
  Object? firstError;

  for (final entry in decoded) {
    if (entry is! Map) {
      skipped++;
      continue;
    }
    try {
      items.add(fromJson(Map<String, dynamic>.from(entry)));
    } on Object catch (error) {
      skipped++;
      firstError ??= error;
    }
  }

  if (skipped > 0 && items.isEmpty) {
    log?.record(
      CacheEventKind.decodeFailed,
      key,
      detail: '${firstError ?? 'no readable rows'}',
    );
    throw FormatException('No row of cached "$key" could be read: $firstError');
  }

  if (skipped > 0) {
    log?.record(
      CacheEventKind.rowsSkipped,
      key,
      detail: '$skipped of ${decoded.length}: $firstError',
    );
  }
  log?.record(CacheEventKind.hit, key, detail: '${items.length} rows');
  return items;
}

/// The saved copy of [key], read straight from the store, for
/// `AsyncView.fallback`.
///
/// `CachedList` seeds a provider only at its element's first build, so a screen
/// whose provider was invalidated, rebuilt for a changed dependency, or built
/// on a branch that skipped [CachedList.persistList] has no seed to show and
/// falls through to a bare spinner. This is the backstop: it renders exactly as
/// a seed would, under the refreshing strip, and costs a `jsonDecode` only on
/// the builds that have nothing else to draw.
///
/// Silent by design - the seed path above is where an outcome gets recorded,
/// and this one runs on every rebuild of a waiting screen.
List<T>? cachedSeedOf<T>(
  WidgetRef ref,
  String key,
  T Function(Map<String, dynamic>) fromJson, {
  List<T> Function(List<T>)? trim,
}) {
  final entry = _readSync(ref.watch(cacheStorageProvider), key);
  if (entry == null || _isExpired(entry)) return null;
  try {
    final items = tolerantDecodeList(entry.data, fromJson, key: key);
    return trim == null ? items : trim(items);
  } on Object {
    return null;
  }
}
