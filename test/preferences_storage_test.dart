import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/cache/cache_log.dart';
import 'package:pham_dash_flutter/core/cache/preferences_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _forever = StorageOptions(cacheTime: StorageCacheTime.unsafe_forever);
const _instant = StorageOptions(cacheTime: StorageCacheTime(Duration.zero));

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'phamdash_theme_mode': 'dark'});
    prefs = await SharedPreferences.getInstance();
  });

  test('round-trips a value with its expiry', () async {
    final store = PreferencesStorage(prefs);
    await store.write(
      'people',
      '[]',
      const StorageOptions(cacheTime: StorageCacheTime(Duration(days: 30))),
    );

    final saved = store.read('people');
    expect(saved!.data, '[]');
    expect(
      saved.expireAt!.difference(DateTime.now().toUtc()).inDays,
      inInclusiveRange(29, 30),
    );
    expect(store.read('missing'), isNull);
  });

  // Riverpod asks for a delete when the provider errors. That is the case
  // this store declines - the saved copy is what the next launch should open
  // to when the database wake outran the request - so only expiry deletes.
  test('delete keeps an unexpired entry and removes an expired one', () async {
    final store = PreferencesStorage(prefs);
    await store.write('live', '1', _forever);
    await store.write('stale', '2', _instant);

    await store.delete('live');
    await store.delete('stale');
    await store.delete('missing');

    expect(store.read('live')!.data, '1');
    expect(store.read('stale'), isNull);
  });

  test('construction sweeps expired entries', () async {
    await PreferencesStorage(prefs).write('stale', '2', _instant);
    await PreferencesStorage(prefs).write('live', '1', _forever);

    // A new instance - what the next launch builds - runs the sweep.
    final next = PreferencesStorage(prefs);
    expect(next.read('stale'), isNull);
    expect(next.read('live')!.data, '1');
  });

  test('a value that is not an envelope is dropped, not thrown', () async {
    await prefs.setString('phamdash_cache:people', 'not json');
    expect(PreferencesStorage(prefs).read('people'), isNull);
    expect(prefs.containsKey('phamdash_cache:people'), isFalse);
  });

  // Sign-out must take the lists with it - and the sort choices keyed on
  // their ids - but nothing else the app keeps in preferences: the theme is
  // the user's, not the session's.
  test('clearAll removes the cache keys and the sort choices, nothing else',
      () async {
    final store = PreferencesStorage(prefs);
    await store.write('people', '[]', _forever);
    await store.write('todo_lists', '[]', _forever);
    await prefs.setStringList(PreferencesStorage.shoppingSortKey, ['10']);
    await prefs.setString(PreferencesStorage.ownerKey, 'user-1');

    await PreferencesStorage.clearAll(prefs);

    expect(store.read('people'), isNull);
    expect(store.read('todo_lists'), isNull);
    expect(prefs.getStringList(PreferencesStorage.shoppingSortKey), isNull);
    expect(prefs.getString(PreferencesStorage.ownerKey), isNull);
    expect(prefs.getString('phamdash_theme_mode'), 'dark');
  });

  // Todo lists are per-user, and that used to be guaranteed by clearing on
  // every sign-out - including the forced ones, which threw the offline copy
  // away over a lapsed token. Claiming on sign-*in* keeps the guarantee and
  // stops a session ending from costing the user their cache.
  group('claimFor', () {
    setUp(() async {
      await PreferencesStorage(prefs).write('todo_lists', '[1]', _forever);
    });

    test('the first claim on a fresh install keeps what is there', () async {
      await PreferencesStorage.claimFor(prefs, 'user-1');

      expect(PreferencesStorage(prefs).read('todo_lists')!.data, '[1]');
      expect(prefs.getString(PreferencesStorage.ownerKey), 'user-1');
    });

    test('the same user again keeps their cache', () async {
      await PreferencesStorage.claimFor(prefs, 'user-1');
      await PreferencesStorage.claimFor(prefs, 'user-1');

      expect(PreferencesStorage(prefs).read('todo_lists')!.data, '[1]');
    });

    test('a different user gets a clean one', () async {
      await prefs.setStringList(PreferencesStorage.shoppingSortKey, ['10']);
      await PreferencesStorage.claimFor(prefs, 'user-1');
      await PreferencesStorage.claimFor(prefs, 'user-2');

      expect(PreferencesStorage(prefs).read('todo_lists'), isNull);
      expect(prefs.getStringList(PreferencesStorage.shoppingSortKey), isNull);
      expect(prefs.getString(PreferencesStorage.ownerKey), 'user-2');
      expect(prefs.getString('phamdash_theme_mode'), 'dark');
    });

    test('records why it cleared', () async {
      final log = CacheLog();
      await PreferencesStorage.claimFor(prefs, 'user-1', log: log);
      expect(log.events, isEmpty);

      await PreferencesStorage.claimFor(prefs, 'user-2', log: log);
      expect(log.events.single.kind, CacheEventKind.cleared);
      expect(log.events.single.detail, 'owner-changed');
    });
  });

  test('describeAll reports each stored key with its size', () async {
    final store = PreferencesStorage(prefs);
    await store.write('people', '[{}]', _forever);
    await store.write('todo_lists', '[]', _instant);

    final described = PreferencesStorage.describeAll(prefs);

    // The expired one was swept on the way through, as it is on every launch.
    expect(described.map((e) => e.key), ['people']);
    expect(described.single.bytes, 4);
    expect(described.single.expireAt, isNull);
  });
}
