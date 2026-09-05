import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/data/models/calendar_models.dart';
import 'package:pham_dash_flutter/features/calendar/event_layout.dart';
import 'package:pham_dash_flutter/features/calendar/event_utils.dart';

final _day = DateTime(2026, 9, 4);

CalendarEvent _event({
  required String id,
  required int startHour,
  required int endHour,
  int startMinute = 0,
  int endMinute = 0,
  String title = 'Event',
  bool isAllDay = false,
  List<EventCategory> categories = const [],
}) =>
    CalendarEvent(
      id: id,
      title: title,
      start: DateTime(2026, 9, 4, startHour, startMinute),
      end: DateTime(2026, 9, 4, endHour, endMinute),
      isAllDay: isAllDay,
      attendees: const [],
      categories: categories,
    );

void main() {
  group('EventLayout', () {
    test('a lone event gets the full width', () {
      final placed = EventLayout.layout([_event(id: 'a', startHour: 9, endHour: 10)], _day);

      expect(placed, hasLength(1));
      expect(placed.single.column, 0);
      expect(placed.single.totalColumns, 1);
    });

    test('two overlapping events split into two lanes', () {
      final placed = EventLayout.layout([
        _event(id: 'a', startHour: 9, endHour: 11),
        _event(id: 'b', startHour: 10, endHour: 12),
      ], _day);

      expect(placed.every((p) => p.totalColumns == 2), isTrue);
      expect(placed.map((p) => p.column).toSet(), {0, 1});
    });

    test('sequential events reuse the same lane', () {
      // b starts exactly when a ends, so they do not overlap.
      final placed = EventLayout.layout([
        _event(id: 'a', startHour: 9, endHour: 10),
        _event(id: 'b', startHour: 10, endHour: 11),
      ], _day);

      expect(placed.every((p) => p.totalColumns == 1), isTrue);
      expect(placed.every((p) => p.column == 0), isTrue);
    });

    test('a third overlapping event opens a third lane', () {
      final placed = EventLayout.layout([
        _event(id: 'a', startHour: 9, endHour: 12),
        _event(id: 'b', startHour: 9, endHour: 12),
        _event(id: 'c', startHour: 9, endHour: 12),
      ], _day);

      expect(placed.every((p) => p.totalColumns == 3), isTrue);
      expect(placed.map((p) => p.column).toSet(), {0, 1, 2});
    });

    test('a freed lane is reused within the same cluster', () {
      // a: 9-10, b: 9-12 (overlaps a), c: 10:30-11 fits back into a's lane.
      final placed = EventLayout.layout([
        _event(id: 'a', startHour: 9, endHour: 10),
        _event(id: 'b', startHour: 9, endHour: 12),
        _event(id: 'c', startHour: 10, startMinute: 30, endHour: 11),
      ], _day);

      final byId = {for (final p in placed) p.event.id: p};
      expect(byId['c']!.column, byId['a']!.column);
      expect(placed.every((p) => p.totalColumns == 2), isTrue);
    });

    test('positions follow the clock', () {
      // The grid starts at 6am, so a 9am event is 3 hours down.
      final placed = EventLayout.layout(
        [_event(id: 'a', startHour: 9, endHour: 10)],
        _day,
      );

      expect(placed.single.top, 3 * 60 * EventLayout.pixelsPerMinute);
      expect(placed.single.height, 60 * EventLayout.pixelsPerMinute);
    });

    test('very short events still get a tappable height', () {
      final placed = EventLayout.layout(
        [_event(id: 'a', startHour: 9, endHour: 9, endMinute: 5)],
        _day,
      );

      expect(placed.single.height, EventLayout.minEventHeight);
    });

    test('all-day events are excluded from the timeline', () {
      final placed = EventLayout.layout([
        _event(id: 'a', startHour: 0, endHour: 0, isAllDay: true),
      ], _day);

      expect(placed, isEmpty);
    });

    test('an event running past the visible range is clamped, not dropped', () {
      // Starts at 5am, before the 6am grid start.
      final placed = EventLayout.layout(
        [_event(id: 'a', startHour: 5, endHour: 8)],
        _day,
      );

      expect(placed, hasLength(1));
      expect(placed.single.top, 0);
    });
  });

  group('EventUtils.hideTuMeetings', () {
    test('drops titles containing the marker', () {
      final events = [
        _event(id: 'a', startHour: 9, endHour: 10, title: 'Tu: Meeting'),
        _event(id: 'b', startHour: 9, endHour: 10, title: 'Weekly Tu: Meeting'),
        _event(id: 'c', startHour: 9, endHour: 10, title: 'Standup'),
      ];

      final kept = EventUtils.hideTuMeetings(events);
      expect(kept.map((e) => e.id), ['c']);
    });

    test('keeps other Tu: events', () {
      // The Kotlin app filters on startsWith("Tu:") and would drop this one.
      final events = [
        _event(id: 'a', startHour: 9, endHour: 10, title: 'Tu: Dentist'),
      ];

      expect(EventUtils.hideTuMeetings(events), hasLength(1));
    });

    test('passes everything through when disabled', () {
      final events = [
        _event(id: 'a', startHour: 9, endHour: 10, title: 'Tu: Meeting'),
      ];

      expect(EventUtils.hideTuMeetings(events, hide: false), hasLength(1));
    });
  });

  group('EventUtils.stripHtml', () {
    test('removes tags and decodes entities', () {
      expect(
        EventUtils.stripHtml('<p>Bring <b>snacks</b> &amp; water</p>'),
        'Bring snacks & water',
      );
    });

    test('turns breaks into newlines', () {
      expect(EventUtils.stripHtml('one<br>two'), 'one\ntwo');
    });

    test('returns null for empty or markup-only input', () {
      expect(EventUtils.stripHtml(null), isNull);
      expect(EventUtils.stripHtml(''), isNull);
      expect(EventUtils.stripHtml('<div></div>'), isNull);
    });
  });

  group('EventUtils.dateHeader', () {
    final now = DateTime(2026, 9, 4, 10);

    test('names today and tomorrow', () {
      expect(EventUtils.dateHeader(DateTime(2026, 9, 4), now: now), 'Today');
      expect(EventUtils.dateHeader(DateTime(2026, 9, 5), now: now), 'Tomorrow');
    });

    test('spells out further dates', () {
      expect(
        EventUtils.dateHeader(DateTime(2026, 9, 9), now: now),
        'Wednesday, Sep 9',
      );
    });
  });

  group('EventUtils.groupByDay', () {
    test('groups by local day in chronological order', () {
      final events = [
        _event(id: 'late', startHour: 15, endHour: 16),
        _event(id: 'early', startHour: 8, endHour: 9),
      ];

      final grouped = EventUtils.groupByDay(events);
      expect(grouped.keys.single, DateTime(2026, 9, 4));
      expect(grouped.values.single.map((e) => e.id), ['late', 'early']);
    });
  });

  group('CalendarEvent.accentColorHex', () {
    test('uses the first category that has a colour', () {
      final event = _event(
        id: 'a',
        startHour: 9,
        endHour: 10,
        categories: const [
          EventCategory(id: 1, name: 'Uncoloured'),
          EventCategory(id: 2, name: 'Con', color: '#8800FF'),
        ],
      );

      expect(event.accentColorHex, '#8800FF');
    });

    test('all-day events fall back to the theme primary', () {
      final event = _event(
        id: 'a',
        startHour: 0,
        endHour: 0,
        isAllDay: true,
        categories: const [EventCategory(id: 2, name: 'Con', color: '#8800FF')],
      );

      expect(event.accentColorHex, isNull);
    });
  });
}
