import 'dart:async';

import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/core/cache/freshness.dart';
import 'package:pham_dash_flutter/core/cache/stale_refresh.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/data/repositories/people_repository.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';

/// `StaleRefresh` against a real keep-alive `CachedList` provider - the tag
/// vocabulary, the smallest of the four it looks after.

class _CountingTags extends PersonTagsRepository {
  _CountingTags(super.api);

  int calls = 0;
  Completer<void>? gate;

  @override
  Future<List<PersonTag>> all() async {
    calls++;
    await gate?.future;
    return const [PersonTag(id: 1, name: 'Coworkers', personCount: 1)];
  }
}

final _now = DateTime(2026, 9, 20, 12);

/// The helper under test, wired like `directoryRefreshProvider` but with a
/// fixed clock and only the one entry.
final _refreshProvider = Provider<StaleRefresh>(
  (ref) => StaleRefresh(
    ref,
    entries: {'person_tags': personTagsProvider},
    now: () => _now,
  ),
);

({ProviderContainer container, _CountingTags tags}) _setUp({
  Completer<void>? gate,
}) {
  final tags = _CountingTags(ApiClient(AuthService()))..gate = gate;
  final container = ProviderContainer(
    overrides: [
      personTagsRepositoryProvider.overrideWithValue(tags),
      cacheStorageProvider.overrideWithValue(Storage.inMemory()),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, tags: tags);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('a provider never built is built - and that first read is the fetch',
      () async {
    final (:container, :tags) = _setUp();

    container.read(_refreshProvider).refreshStale();
    await _settle();
    expect(tags.calls, 1);

    // The build's own completion stamped it, so a second pass is a no-op.
    await container.read(personTagsProvider.future);
    await _settle();
    container.read(_refreshProvider).refreshStale();
    await _settle();
    expect(tags.calls, 1);
  });

  test('a fresh stamp is left alone; a stale one is refetched', () async {
    final (:container, :tags) = _setUp();
    await container.read(personTagsProvider.future);
    await _settle();
    expect(tags.calls, 1);

    // Ten minutes old: inside the window.
    container
        .read(freshnessProvider.notifier)
        .mark('person_tags', at: _now.subtract(const Duration(minutes: 10)));
    container.read(_refreshProvider).refreshStale();
    await _settle();
    expect(tags.calls, 1);

    // An hour old: refetched.
    container
        .read(freshnessProvider.notifier)
        .mark('person_tags', at: _now.subtract(const Duration(hours: 1)));
    container.read(_refreshProvider).refreshStale();
    await _settle();
    expect(tags.calls, 2);
  });

  test('a fetch already in flight is not doubled by a resume burst', () async {
    final gate = Completer<void>();
    final (:container, :tags) = _setUp(gate: gate);

    final refresh = container.read(_refreshProvider);
    refresh.refreshStale();
    refresh.refreshStale();
    await _settle();
    refresh.refreshStale();
    expect(tags.calls, 1);

    gate.complete();
    await container.read(personTagsProvider.future);
  });

  test('a refresh it triggers writes a freshness stamp when it lands',
      () async {
    final (:container, :tags) = _setUp();
    await container.read(personTagsProvider.future);
    await _settle();
    container
        .read(freshnessProvider.notifier)
        .mark('person_tags', at: _now.subtract(const Duration(days: 1)));

    container.read(_refreshProvider).refreshStale();
    await container.read(personTagsProvider.future);
    await _settle();

    expect(tags.calls, 2);
    final stamp = container.read(freshnessProvider)['person_tags'];
    expect(DateTime.now().difference(stamp!).inSeconds, lessThan(5));
  });
}
