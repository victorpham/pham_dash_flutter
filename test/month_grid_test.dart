import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/data/models/calendar_models.dart';
import 'package:pham_dash_flutter/features/calendar/month_grid.dart';

/// A busy day: more events than any cell can hold, so every cell has to
/// truncate and show the "+N more" line.
List<CalendarEvent> _busyDay(DateTime day, int count) => [
      for (var i = 0; i < count; i++)
        CalendarEvent(
          id: '$i',
          title: 'Event number $i with a long title',
          start: DateTime(day.year, day.month, day.day, 8 + i),
          end: DateTime(day.year, day.month, day.day, 9 + i),
          isAllDay: false,
          attendees: const [],
          categories: const [],
        ),
    ];

Future<void> _pumpGrid(
  WidgetTester tester, {
  required Size size,
  required List<CalendarEvent> events,
  double textScale = 1.0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: MonthGrid(
              month: DateTime(2026, 9),
              events: events,
              onDayTap: (_, _) {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('MonthGrid day cells', () {
    // 404.6 logical pixels wide reproduces the 57.8pt cell (and the 87.8pt
    // content box) from the emulator that overflowed by 1.7 pixels.
    testWidgets('do not overflow at the width that used to overflow',
        (tester) async {
      await _pumpGrid(
        tester,
        size: const Size(404.6, 780),
        events: _busyDay(DateTime(2026, 9, 15), 8),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('do not overflow on a narrow phone', (tester) async {
      await _pumpGrid(
        tester,
        size: const Size(320, 600),
        events: _busyDay(DateTime(2026, 9, 15), 8),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('do not overflow at a large text scale', (tester) async {
      await _pumpGrid(
        tester,
        size: const Size(404.6, 780),
        events: _busyDay(DateTime(2026, 9, 15), 8),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('a truncated day still reports the hidden events',
        (tester) async {
      await _pumpGrid(
        tester,
        size: const Size(404.6, 780),
        events: _busyDay(DateTime(2026, 9, 15), 8),
      );

      // Whatever the fitted pill count is, the count in "+N more" has to
      // account for exactly the events that were left out.
      final pills = find.textContaining('Event number');
      final shown = tester.widgetList(pills).length;
      expect(shown, greaterThan(0));
      expect(find.text('+${8 - shown} more'), findsOneWidget);
    });

    testWidgets('a day that fits shows every event and no overflow line',
        (tester) async {
      await _pumpGrid(
        tester,
        size: const Size(404.6, 780),
        events: _busyDay(DateTime(2026, 9, 15), 2),
      );

      expect(tester.takeException(), isNull);
      expect(tester.widgetList(find.textContaining('Event number')).length, 2);
      expect(find.textContaining('more'), findsNothing);
    });
  });
}
