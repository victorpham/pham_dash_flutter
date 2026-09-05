import '../../core/api/api_date.dart';
import '../../data/models/calendar_models.dart';

/// An event placed on a day timeline.
class PositionedEvent {
  const PositionedEvent({
    required this.event,
    required this.column,
    required this.totalColumns,
    required this.top,
    required this.height,
  });

  final CalendarEvent event;

  /// Which of [totalColumns] side-by-side lanes this event occupies.
  final int column;
  final int totalColumns;

  /// Offset and extent in logical pixels from the top of the day.
  final double top;
  final double height;
}

class HourMarker {
  const HourMarker(this.hour, this.label, this.offset);

  final int hour;
  final String label;
  final double offset;
}

/// Lays out a day's events into non-overlapping columns.
///
/// Ported from the Kotlin `EventOverlapCalculator`, which is a faithful
/// implementation of the greedy column assignment the web week view uses:
/// sort by start (longer first on ties), group into clusters of mutually
/// overlapping events, then give each event the first column that is free at
/// its start time.
class EventLayout {
  const EventLayout._();

  static const int dayStartHour = 6; // 6am
  static const int dayEndHour = 22; // 10pm
  static const double pixelsPerMinute = 2;
  static const double minEventHeight = 30;

  static double get dayHeight =>
      (dayEndHour - dayStartHour) * 60 * pixelsPerMinute;

  static List<HourMarker> get hourMarkers => [
        for (var hour = dayStartHour; hour < dayEndHour; hour++)
          HourMarker(
            hour,
            _hourLabel(hour),
            (hour - dayStartHour) * 60 * pixelsPerMinute,
          ),
      ];

  static String _hourLabel(int hour) {
    if (hour == 0) return '12a';
    if (hour == 12) return '12p';
    return hour < 12 ? '${hour}a' : '${hour - 12}p';
  }

  /// Where "now" sits on the timeline, or null when outside the visible hours.
  static double? currentTimeOffset(DateTime now) {
    if (now.hour < dayStartHour || now.hour >= dayEndHour) return null;
    return ((now.hour - dayStartHour) * 60 + now.minute) * pixelsPerMinute;
  }

  static List<PositionedEvent> layout(List<CalendarEvent> events, DateTime day) {
    final dayStart = ApiDate.startOfDay(day).add(
      const Duration(hours: dayStartHour),
    );
    final dayEnd = ApiDate.startOfDay(day).add(
      const Duration(hours: dayEndHour),
    );

    final visible = events
        .where(
          (event) =>
              !event.isAllDay &&
              event.start.isBefore(dayEnd) &&
              event.end.isAfter(dayStart),
        )
        .toList();
    if (visible.isEmpty) return const [];

    // Start ascending; on a tie the longer event first, which stacks better.
    visible.sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      if (byStart != 0) return byStart;
      return b.end.difference(b.start).compareTo(a.end.difference(a.start));
    });

    final entries = [
      for (final event in visible)
        _Entry(
          event: event,
          startMinute: _minutesFrom(dayStart, event.start),
          endMinute: _minutesFrom(dayStart, event.end),
        ),
    ];

    _assignColumns(entries);

    return [
      for (final entry in entries)
        PositionedEvent(
          event: entry.event,
          column: entry.column,
          totalColumns: entry.totalColumns,
          top: entry.startMinute * pixelsPerMinute,
          height: _heightFor(entry),
        ),
    ];
  }

  static double _heightFor(_Entry entry) {
    final height = (entry.endMinute - entry.startMinute) * pixelsPerMinute;
    return height < minEventHeight ? minEventHeight : height;
  }

  /// Walks the sorted events, closing a cluster whenever an event starts after
  /// everything before it has ended, then colours each cluster greedily.
  static void _assignColumns(List<_Entry> entries) {
    var clusterStart = 0;
    var clusterEnd = -1 << 30;

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];

      if (i > clusterStart && entry.startMinute >= clusterEnd) {
        _colour(entries.sublist(clusterStart, i));
        clusterStart = i;
        clusterEnd = entry.endMinute;
      } else {
        if (entry.endMinute > clusterEnd) clusterEnd = entry.endMinute;
      }
    }

    if (clusterStart < entries.length) {
      _colour(entries.sublist(clusterStart));
    }
  }

  static void _colour(List<_Entry> cluster) {
    final columnFreeAt = <int>[];

    for (final entry in cluster) {
      var placed = false;
      for (var column = 0; column < columnFreeAt.length; column++) {
        if (columnFreeAt[column] <= entry.startMinute) {
          entry.column = column;
          columnFreeAt[column] = entry.endMinute;
          placed = true;
          break;
        }
      }
      if (!placed) {
        entry.column = columnFreeAt.length;
        columnFreeAt.add(entry.endMinute);
      }
    }

    for (final entry in cluster) {
      entry.totalColumns = columnFreeAt.length;
    }
  }

  /// Minutes from the top of the visible day, clamped to it so an event that
  /// starts at 5am or runs past midnight still renders inside the grid.
  static int _minutesFrom(DateTime dayStart, DateTime value) {
    final minutes = value.difference(dayStart).inMinutes;
    final maxMinutes = (dayEndHour - dayStartHour) * 60;
    if (minutes < 0) return 0;
    if (minutes > maxMinutes) return maxMinutes;
    return minutes;
  }
}

class _Entry {
  _Entry({
    required this.event,
    required this.startMinute,
    required this.endMinute,
  });

  final CalendarEvent event;
  final int startMinute;
  final int endMinute;
  int column = 0;
  int totalColumns = 1;
}
