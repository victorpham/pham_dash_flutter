import 'dart:convert';

import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/decode.dart';
import '../providers.dart';

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
/// Storage is [PreferencesStorage]; a failed refresh keeps the saved copy on
/// purpose - see there.
mixin CachedList<T> on AsyncNotifier<List<T>> {
  /// Long enough that a phone left in a drawer still opens to its lists; short
  /// enough that a provider removed from the app does not leave its data
  /// behind forever.
  static const StorageCacheTime cacheTime =
      StorageCacheTime(Duration(days: 30));

  /// Seeds the state from [key] on the notifier's first build and writes every
  /// later `AsyncData` back. [trim] is applied to the cached list only - the
  /// schedule uses it to drop events that ended before today.
  ///
  /// Skip the call, rather than vary the key, when the current build is not
  /// the launch view (a filtered todo list): the write-back listener is
  /// re-registered per build, so a build without this call writes nothing.
  void persistList(
    String key, {
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    List<T> Function(List<T>)? trim,
  }) {
    persist(
      ref.watch(cacheStorageProvider),
      key: key,
      encode: (items) => encodeList(items, toJson),
      decode: (encoded) {
        final items = decodeEncodedList(encoded, fromJson);
        return trim == null ? items : trim(items);
      },
      options: const StorageOptions(cacheTime: cacheTime),
    );
  }
}

/// The stored form: a JSON array of each item's wire shape, so the same
/// `fromJson` that reads the API reads the cache.
String encodeList<T>(List<T> items, Map<String, dynamic> Function(T) toJson) =>
    jsonEncode([for (final item in items) toJson(item)]);

List<T> decodeEncodedList<T>(
  String encoded,
  T Function(Map<String, dynamic>) fromJson,
) =>
    decodeList(jsonDecode(encoded), fromJson);

