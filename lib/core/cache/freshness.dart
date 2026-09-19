import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'cached_list.dart';

/// When each cached key was last confirmed against the server.
///
/// The cache itself only records when an entry *expires*, and a screen that
/// renders a saved copy looks exactly like one that just refreshed once the
/// strip is gone. This is the missing half: a stamp per key, written when a
/// fetch completes, so a screen can say "Updated 10:42" - or "Updated
/// yesterday", which is the honest thing to show over a list that could not
/// refresh.
///
/// Stored through the same `Storage` as the lists, so the in-memory store in
/// tests carries it, and sign-out's prefix sweep clears it with everything
/// else. One entry holds every key: there are a dozen or so, and per-list
/// keys arrive slowly.
final freshnessProvider =
    NotifierProvider<FreshnessNotifier, Map<String, DateTime>>(
      FreshnessNotifier.new,
    );

class FreshnessNotifier extends Notifier<Map<String, DateTime>> {
  static const String storageKey = 'fetched_at';

  @override
  Map<String, DateTime> build() {
    final storage = ref.watch(cacheStorageProvider);
    final read = storage.read(storageKey);
    // PreferencesStorage and the in-memory store both answer synchronously;
    // an async store would seed empty and fill in on its first mark.
    if (read is Future<PersistedData<String>?>) {
      unawaited(
        read.then((entry) {
          if (entry != null && state.isEmpty) state = _decode(entry.data);
        }),
      );
      return const {};
    }
    return read == null ? const {} : _decode(read.data);
  }

  /// Records that [key] was just fetched from the server.
  void mark(String key, {DateTime? at}) {
    state = {...state, key: at ?? DateTime.now()};
    ref
        .read(cacheStorageProvider)
        .write(
          storageKey,
          jsonEncode({
            for (final entry in state.entries)
              entry.key: entry.value.toUtc().toIso8601String(),
          }),
          const StorageOptions(cacheTime: CachedList.cacheTime),
        );
  }

  static Map<String, DateTime> _decode(String encoded) {
    try {
      final map = jsonDecode(encoded) as Map<String, dynamic>;
      return {
        for (final entry in map.entries)
          entry.key: DateTime.parse(entry.value as String).toLocal(),
      };
    } on FormatException {
      return const {};
    }
  }
}

/// The last fetch time for [key], or null if it has never been fetched here.
DateTime? freshnessOf(WidgetRef ref, String key) =>
    ref.watch(freshnessProvider.select((stamps) => stamps[key]));

/// For a notifier's `listenSelf`: marks [key] fresh when a fetch completes.
///
/// A fetch is a loading state turning into data that did not come from the
/// cache - which excludes both the cache seed on launch and the optimistic
/// patches the todo notifiers make (those go data -> data). Called from
/// inside the notifier because `listenSelf` and `ref` are protected there.
void recordFetch<T>(
  Ref ref,
  String key,
  AsyncValue<T>? previous,
  AsyncValue<T> next,
) {
  if (previous?.isLoading != true) return;
  if (next is! AsyncData<T> || next.isFromCache) return;
  ref.read(freshnessProvider.notifier).mark(key);
}
