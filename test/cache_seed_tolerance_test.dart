import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/cache/cache_log.dart';
import 'package:pham_dash_flutter/core/cache/cached_list.dart';
import 'package:pham_dash_flutter/data/models/todo_models.dart';

/// A cached copy is written by whichever build of the app happened to be
/// installed at the time, and read by whichever one is installed now. A model
/// that gained a required field in between makes the old rows unreadable - and
/// until this was tolerant, one such row cost the whole tab its launch view and
/// left a bare spinner for the length of a database wake, silently.
void main() {
  late CacheLog log;

  setUp(() => log = CacheLog());

  final list = TodoList(
    id: 5,
    title: 'Groceries',
    isPinned: false,
    isArchived: false,
    displayOrder: 1,
    createdAt: DateTime.utc(2026, 8, 30, 12).toLocal(),
    items: const [],
    groups: const [],
    labels: const [],
    totalItems: 0,
    completedItems: 0,
  );

  String encodedWith(List<Object?> extra) {
    final rows = jsonDecode(encodeList([list], (l) => l.toJson())) as List;
    return jsonEncode([...rows, ...extra]);
  }

  List<TodoList> decode(String encoded) => tolerantDecodeList(
        encoded,
        TodoList.fromJson,
        key: 'todo_lists',
        log: log,
      );

  test('a clean payload is a hit', () {
    expect(decode(encodedWith(const [])).single.title, 'Groceries');
    expect(log.events.single.kind, CacheEventKind.hit);
    expect(log.events.single.detail, '1 rows');
  });

  // `title` and `groups` are required with no default, so a row without them
  // is exactly what an older cached copy looks like after a model change.
  test('one unreadable row is skipped, the rest survive', () {
    final lists = decode(encodedWith([
      {'id': 99},
    ]));

    expect(lists.single.id, 5);
    expect(
      log.events.map((e) => e.kind),
      containsAll([CacheEventKind.rowsSkipped, CacheEventKind.hit]),
    );
    expect(
      log.events.firstWhere((e) => e.kind == CacheEventKind.rowsSkipped).detail,
      startsWith('1 of 2'),
    );
  });

  test('a row that is not an object is skipped too', () {
    expect(decode(encodedWith(['nonsense', 7])).single.id, 5);
    expect(
      log.events.firstWhere((e) => e.kind == CacheEventKind.rowsSkipped).detail,
      startsWith('2 of 3'),
    );
  });

  // Throwing rather than returning [] matters: Riverpod catches the throw and
  // leaves the provider unseeded, whereas an empty list would seed "no lists
  // yet" over a directory that does exist.
  test('a payload with nothing readable throws rather than seeding empty', () {
    expect(
      () => decode(jsonEncode([
        {'id': 1},
        {'id': 2},
      ])),
      throwsFormatException,
    );
    expect(log.events.first.kind, CacheEventKind.decodeFailed);
  });

  test('a payload that is not an array throws', () {
    expect(() => decode(jsonEncode({'oops': true})), throwsFormatException);
    expect(log.events.single.detail, 'payload is not a JSON array');
  });

  // An empty list is a real answer - the user has no lists - and must seed as
  // one rather than be mistaken for an unreadable payload.
  test('an empty array seeds an empty list', () {
    expect(decode('[]'), isEmpty);
    expect(log.events.single.kind, CacheEventKind.hit);
  });
}
