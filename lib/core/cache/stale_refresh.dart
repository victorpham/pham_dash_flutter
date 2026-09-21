import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'freshness.dart';

/// A `CachedList` provider as [StaleRefresh] sees it. Dart generics are
/// covariant, so any `AsyncNotifierProvider<SomeNotifier, List<T>>` fits
/// without this file importing the feature that declares it.
typedef CachedListProvider = AsyncNotifierProvider<AsyncNotifier<Object?>, Object?>;

/// Re-reads keep-alive cached lists that have gone stale.
///
/// A keep-alive `CachedList` provider fetches once, on its first read, and
/// then holds that answer for the life of the app - correct for a directory
/// that changes a few times a year, wrong for a phone that was in a pocket all
/// afternoon. This is the missing "check for new data": on launch, on resume
/// and when the people list opens, every entry whose freshness stamp is older
/// than [window] is refreshed, and one that was never built is built.
///
/// It is deliberately blunt. The API has no "changed since" and the records
/// carry no `updatedAt`, so a check is a full refetch; the lists are
/// family-sized and that is cheap. What is not cheap is waking the database,
/// which is why the window exists and why the dashboard chains this behind
/// `ServerWarmup.ping()` rather than firing it alongside.
class StaleRefresh {
  StaleRefresh(
    this._ref, {
    required this.entries,
    this.window = const Duration(minutes: 15),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Ref _ref;

  /// Freshness key -> the provider that `persistList`s under that key.
  final Map<String, CachedListProvider> entries;

  /// How old a list may be before an open or a resume refetches it.
  final Duration window;

  final DateTime Function() _now;

  /// Refreshes every stale entry. Never throws: a provider's failure lands in
  /// its own `AsyncError`, where its screen already knows how to show it.
  void refreshStale() {
    final stamps = _ref.read(freshnessProvider);
    final now = _now();

    for (final MapEntry(key: key, value: provider) in entries.entries) {
      // Reading a never-built keep-alive provider builds it, and that first
      // build is the fetch. A cache-seeded first build is `AsyncLoading` with a
      // value, so the same check covers it and a fetch already in flight:
      // resume events come in bursts, and one refresh is enough.
      if (_ref.read(provider).isLoading) continue;

      final fetchedAt = stamps[key];
      if (fetchedAt != null && now.difference(fetchedAt) < window) continue;

      // `invalidate` alone is lazy - a keep-alive provider nobody is watching
      // would not rebuild until its next read. `refresh` reads, and that read
      // is the point; nobody here needs the value.
      // ignore: unused_result
      _ref.refresh(provider);
    }
  }
}
