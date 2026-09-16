import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_test/flutter_test.dart';
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

  // Sign-out must take the lists with it, but nothing else the app keeps in
  // preferences - the theme is the user's, not the session's.
  test('clearAll removes only cache keys', () async {
    final store = PreferencesStorage(prefs);
    await store.write('people', '[]', _forever);
    await store.write('todo_lists', '[]', _forever);

    await PreferencesStorage.clearAll(prefs);

    expect(store.read('people'), isNull);
    expect(store.read('todo_lists'), isNull);
    expect(prefs.getString('phamdash_theme_mode'), 'dark');
  });
}
