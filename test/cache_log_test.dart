import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/cache/cache_log.dart';

void main() {
  test('reports newest first', () {
    final log = CacheLog();
    log.record(CacheEventKind.miss, 'people');
    log.record(CacheEventKind.hit, 'todo_lists', detail: '3 rows');

    expect(log.events.map((e) => e.key), ['todo_lists', 'people']);
    expect(log.events.first.detail, '3 rows');
    expect(log.events.first.toString(), 'todo_lists: hit (3 rows)');
    expect(log.events.last.toString(), 'people: miss');
  });

  // The buffer is what a phone carries between "that looked wrong" and opening
  // the diagnostics screen, so it has to stay small and drop the oldest rather
  // than grow without limit.
  test('keeps the most recent entries and no more', () {
    final log = CacheLog();
    for (var i = 0; i < CacheLog.capacity + 10; i++) {
      log.record(CacheEventKind.miss, 'key$i');
    }

    expect(log.events, hasLength(CacheLog.capacity));
    expect(log.events.first.key, 'key${CacheLog.capacity + 9}');
    expect(log.events.last.key, 'key10');
  });

  test('clear empties it', () {
    final log = CacheLog()..record(CacheEventKind.cleared, '*');
    log.clear();
    expect(log.events, isEmpty);
  });
}
