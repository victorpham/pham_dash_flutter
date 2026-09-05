import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_date.dart';

void main() {
  group('wallClock', () {
    test('keeps the literal clock components, whatever the device zone', () {
      final parsed = ApiDate.wallClock('2026-09-04T18:30:00')!;

      expect(parsed.year, 2026);
      expect(parsed.month, 9);
      expect(parsed.day, 4);
      expect(parsed.hour, 18);
      expect(parsed.minute, 30);
      // Must not be flagged UTC: doing so would let a later toLocal() shift it.
      expect(parsed.isUtc, isFalse);
    });

    test('strips a Z rather than converting, so an event never moves', () {
      // Google-sourced events are wall-clock in the calendar's own timezone.
      // A stray Z must not drag the time across the device's offset.
      final withZ = ApiDate.wallClock('2026-09-04T18:30:00Z')!;
      expect(withZ.hour, 18);
      expect(withZ.minute, 30);
    });

    test('strips an explicit offset too', () {
      final withOffset = ApiDate.wallClock('2026-09-04T18:30:00-07:00')!;
      expect(withOffset.hour, 18);
    });

    test('handles all-day events, stored as midnight', () {
      final allDay = ApiDate.wallClock('2026-09-04T00:00:00')!;
      expect(allDay.hour, 0);
      expect(ApiDate.isSameDay(allDay, DateTime(2026, 9, 4)), isTrue);
    });

    test('returns null for null and empty', () {
      expect(ApiDate.wallClock(null), isNull);
      expect(ApiDate.wallClock(''), isNull);
    });
  });

  group('utcStamp', () {
    test('treats a marker-less audit timestamp as UTC', () {
      // createdAt/updatedAt are written as DateTime.UtcNow but lose their Z on
      // a SQL Server round trip. Parsing them as local would misreport them by
      // the device's offset.
      final parsed = ApiDate.utcStamp('2026-09-04T18:30:00')!;
      expect(parsed.toUtc().hour, 18);
      expect(parsed.isUtc, isFalse, reason: 'returned in local time for display');
    });

    test('respects a Z that is already present', () {
      // syncStatus.lastSyncedAt is the one field explicitly stamped Utc.
      final parsed = ApiDate.utcStamp('2026-09-04T18:30:00Z')!;
      expect(parsed.toUtc().hour, 18);
    });

    test('agrees with wallClock only in UTC', () {
      final wall = ApiDate.wallClock('2026-09-04T18:30:00')!;
      final utc = ApiDate.utcStamp('2026-09-04T18:30:00')!;
      final offset = DateTime.now().timeZoneOffset;

      expect(utc.difference(wall), offset);
    });
  });

  group('serialization', () {
    test('formatWallClock emits no zone marker', () {
      final formatted = ApiDate.formatWallClock(DateTime(2026, 9, 4, 18, 30, 5));
      expect(formatted, '2026-09-04T18:30:05');
      expect(formatted, isNot(contains('Z')));
    });

    test('formatQueryInstant emits UTC with Z, matching toISOString()', () {
      final formatted = ApiDate.formatQueryInstant(
        DateTime.utc(2026, 9, 4, 18, 30),
      );
      expect(formatted, startsWith('2026-09-04T18:30:00'));
      expect(formatted, endsWith('Z'));
    });

    test('a wall-clock value survives a format/parse round trip', () {
      final original = DateTime(2026, 9, 4, 18, 30, 5);
      final round = ApiDate.wallClock(ApiDate.formatWallClock(original))!;
      expect(round, original);
    });
  });

  group('scheduledTime', () {
    test('parses "HH:mm" into minutes since midnight', () {
      expect(ApiDate.parseMinutesOfDay('07:30'), 450);
      expect(ApiDate.parseMinutesOfDay('00:00'), 0);
      expect(ApiDate.parseMinutesOfDay('23:59'), 1439);
    });

    test('rejects malformed and out-of-range values', () {
      for (final bad in ['', 'seven', '7', '25:00', '07:99']) {
        expect(ApiDate.parseMinutesOfDay(bad), isNull, reason: bad);
      }
      expect(ApiDate.parseMinutesOfDay(null), isNull);
    });

    test('round trips through formatMinutesOfDay', () {
      expect(ApiDate.formatMinutesOfDay(450), '07:30');
      expect(ApiDate.formatMinutesOfDay(0), '00:00');
    });
  });

  group('scheduledDays', () {
    test('parses the CSV of 0=Sun..6=Sat', () {
      expect(ApiDate.parseScheduledDays('1,2,3,4,5'), {1, 2, 3, 4, 5});
      expect(ApiDate.parseScheduledDays(' 0 , 6 '), {0, 6});
    });

    test('null or empty means every day, represented as an empty set', () {
      expect(ApiDate.parseScheduledDays(null), isEmpty);
      expect(ApiDate.parseScheduledDays(''), isEmpty);
      expect(ApiDate.parseScheduledDays('   '), isEmpty);
    });

    test('discards junk and out-of-range days', () {
      expect(ApiDate.parseScheduledDays('1,x,9,-2,3'), {1, 3});
    });

    test('formats back to CSV, and every-day back to null', () {
      expect(ApiDate.formatScheduledDays({3, 1, 2}), '1,2,3');
      expect(ApiDate.formatScheduledDays({}), isNull);
    });

    test('jsWeekday maps Dart Mon=1..Sun=7 onto JS Sun=0..Sat=6', () {
      // 2026-09-06 is a Sunday.
      expect(ApiDate.jsWeekday(DateTime(2026, 9, 6)), 0);
      expect(ApiDate.jsWeekday(DateTime(2026, 9, 7)), 1); // Monday
      expect(ApiDate.jsWeekday(DateTime(2026, 9, 12)), 6); // Saturday
    });
  });

  group('day helpers', () {
    test('dayKey is the yyyy-MM-dd the dismissal store is keyed by', () {
      expect(ApiDate.dayKey(DateTime(2026, 9, 4, 23, 59)), '2026-09-04');
      expect(ApiDate.dayKey(DateTime(2026, 12, 25)), '2026-12-25');
    });

    test('startOfDay drops the time', () {
      expect(
        ApiDate.startOfDay(DateTime(2026, 9, 4, 18, 30)),
        DateTime(2026, 9, 4),
      );
    });
  });
}
