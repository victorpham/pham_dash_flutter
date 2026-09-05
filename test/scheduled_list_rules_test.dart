import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/data/models/todo_models.dart';
import 'package:pham_dash_flutter/features/scheduled_lists/time_status.dart';

/// 2026-09-04 is a Friday, so jsWeekday == 5.
final _friday10am = DateTime(2026, 9, 4, 10, 0);

TodoList _list({
  int id = 1,
  String title = 'Morning routine',
  String? scheduledTime,
  String? scheduledDays,
  LinkedEvent? linkedEvent,
  List<TodoItem> items = const [],
  List<TodoItemGroup> groups = const [],
}) =>
    TodoList(
      id: id,
      title: title,
      isPinned: false,
      isArchived: false,
      displayOrder: 0,
      scheduledTime: scheduledTime,
      scheduledDays: scheduledDays,
      linkedEvent: linkedEvent,
      items: items,
      groups: groups,
      labels: const [],
      totalItems: items.length,
      completedItems: items.where((i) => i.isCompleted).length,
    );

TodoItem _item(int id, {bool completed = false}) => TodoItem(
      id: id,
      todoListId: 1,
      content: 'Item $id',
      isCompleted: completed,
      displayOrder: id,
      indentLevel: 0,
    );

void main() {
  group('day-of-week filter', () {
    test('an empty scheduledDays means every day', () {
      final list = _list(scheduledTime: '10:00');
      expect(ScheduledListRules.isVisibleToday(list, _friday10am), isTrue);
    });

    test('shows only on the listed days', () {
      // Weekdays Mon-Fri; Friday is 5.
      final weekdays = _list(scheduledTime: '10:00', scheduledDays: '1,2,3,4,5');
      expect(ScheduledListRules.isVisibleToday(weekdays, _friday10am), isTrue);

      final weekend = _list(scheduledTime: '10:00', scheduledDays: '0,6');
      expect(ScheduledListRules.isVisibleToday(weekend, _friday10am), isFalse);
    });

    test('event-linked lists ignore the day filter entirely', () {
      // The server already windowed these, and they carry no scheduledDays.
      final list = _list(
        scheduledDays: '0,6',
        linkedEvent: LinkedEvent(
          eventId: 'e1',
          eventStart: _friday10am.add(const Duration(hours: 2)),
          isAllDay: false,
        ),
      );
      expect(ScheduledListRules.isVisibleToday(list, _friday10am), isTrue);
    });
  });

  group('active window', () {
    test('becomes active exactly five minutes before its time', () {
      final list = _list(scheduledTime: '10:05');
      expect(ScheduledListRules.isActive(list, _friday10am), isTrue);
    });

    test('is not yet active six minutes before', () {
      final list = _list(scheduledTime: '10:06');
      expect(ScheduledListRules.isActive(list, _friday10am), isFalse);
      expect(ScheduledListRules.isUpcoming(list, _friday10am), isTrue);
    });

    test('stays active for the rest of the day once passed', () {
      // The Kotlin engine drops a list after 60 minutes; the web keeps it.
      final list = _list(scheduledTime: '07:00');
      expect(ScheduledListRules.isActive(list, _friday10am), isTrue);

      final lateEvening = DateTime(2026, 9, 4, 23, 30);
      expect(ScheduledListRules.isActive(list, lateEvening), isTrue);
    });

    test('a list that fails the day filter is never active', () {
      final list = _list(scheduledTime: '07:00', scheduledDays: '0,6');
      expect(ScheduledListRules.isActive(list, _friday10am), isFalse);
    });
  });

  group('status labels', () {
    test('within five minutes either way reads "Now"', () {
      for (final time in ['09:55', '10:00', '10:05']) {
        final status =
            ScheduledListRules.statusFor(_list(scheduledTime: time), _friday10am);
        expect(status.label, 'Now', reason: time);
        expect(status.tone, StatusTone.now);
      }
    });

    test('future times read "In N min" then "In Xh Ym"', () {
      expect(
        ScheduledListRules.statusFor(_list(scheduledTime: '10:20'), _friday10am)
            .label,
        'In 20 min',
      );
      expect(
        ScheduledListRules.statusFor(_list(scheduledTime: '12:05'), _friday10am)
            .label,
        'In 2h 5m',
      );
      expect(
        ScheduledListRules.statusFor(_list(scheduledTime: '12:00'), _friday10am)
            .label,
        'In 2h',
      );
    });

    test('past times read "N min ago" and are muted', () {
      final status =
          ScheduledListRules.statusFor(_list(scheduledTime: '09:40'), _friday10am);
      expect(status.label, '20 min ago');
      expect(status.tone, StatusTone.past);

      expect(
        ScheduledListRules.statusFor(_list(scheduledTime: '07:55'), _friday10am)
            .label,
        '2h 5m ago',
      );
    });
  });

  group('event-linked status', () {
    TodoList eventAt(DateTime start) => _list(
          linkedEvent:
              LinkedEvent(eventId: 'e1', eventStart: start, isAllDay: false),
        );

    test('an event under an hour away is the accent colour', () {
      final status = ScheduledListRules.statusFor(
        eventAt(_friday10am.add(const Duration(minutes: 40))),
        _friday10am,
      );
      expect(status.label, 'Event in 40m');
      expect(status.tone, StatusTone.now);
    });

    test('an event later today reads in hours', () {
      expect(
        ScheduledListRules.statusFor(
          eventAt(_friday10am.add(const Duration(hours: 6))),
          _friday10am,
        ).label,
        'Event in 6h',
      );
    });

    test('a started event is flagged, and then counts up', () {
      expect(
        ScheduledListRules.statusFor(
          eventAt(_friday10am.subtract(const Duration(minutes: 10))),
          _friday10am,
        ).label,
        'Event started',
      );

      final long = ScheduledListRules.statusFor(
        eventAt(_friday10am.subtract(const Duration(hours: 3))),
        _friday10am,
      );
      expect(long.label, 'Started 3h ago');
      expect(long.tone, StatusTone.started);
    });

    test('further-out events read Tomorrow, then in days', () {
      expect(
        ScheduledListRules.statusFor(
          eventAt(_friday10am.add(const Duration(hours: 26))),
          _friday10am,
        ).label,
        'Tomorrow',
      );
      expect(
        ScheduledListRules.statusFor(
          eventAt(_friday10am.add(const Duration(days: 2))),
          _friday10am,
        ).label,
        'In 2 days',
      );
    });
  });

  group('classify', () {
    test('sorts the most overdue list first', () {
      final lists = [
        _list(id: 1, scheduledTime: '10:03'), // 3 min away
        _list(id: 2, scheduledTime: '07:00'), // 3h overdue
        _list(id: 3, scheduledTime: '09:30'), // 30 min overdue
      ];

      final result = ScheduledListRules.classify(lists, _friday10am);

      expect(result.active.map((l) => l.id), [2, 3, 1]);
    });

    test('picks the earliest future list as "up next"', () {
      final lists = [
        _list(id: 1, scheduledTime: '18:00'),
        _list(id: 2, scheduledTime: '11:00'),
        _list(id: 3, scheduledTime: '14:00'),
      ];

      final result = ScheduledListRules.classify(lists, _friday10am);

      expect(result.active, isEmpty);
      expect(result.upNext?.id, 2);
    });

    test('excludes lists that do not run today', () {
      final lists = [
        _list(id: 1, scheduledTime: '07:00', scheduledDays: '0,6'),
        _list(id: 2, scheduledTime: '07:00', scheduledDays: '5'),
      ];

      final result = ScheduledListRules.classify(lists, _friday10am);

      expect(result.active.map((l) => l.id), [2]);
    });
  });

  group('completedLast', () {
    test('sinks completed items while preserving relative order', () {
      final items = [
        _item(1, completed: true),
        _item(2),
        _item(3, completed: true),
        _item(4),
      ];

      expect(
        ScheduledListRules.completedLast(items).map((i) => i.id),
        [2, 4, 1, 3],
      );
    });
  });

  group('TodoList.allItems', () {
    test('spans ungrouped items and every group', () {
      // The API puts only ungrouped items in `items`; a UI that renders that
      // list alone silently drops everything inside a group.
      final list = _list(
        items: [_item(1)],
        groups: [
          TodoItemGroup(
            id: 10,
            todoListId: 1,
            name: 'Upstairs',
            displayOrder: 0,
            items: [_item(2), _item(3)],
          ),
        ],
      );

      expect(list.items.length, 1);
      expect(list.allItems.map((i) => i.id), [1, 2, 3]);
    });
  });
}
