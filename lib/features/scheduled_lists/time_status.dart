import '../../core/api/api_date.dart';
import '../../data/models/todo_models.dart';

/// How a status label should be coloured.
enum StatusTone {
  /// Happening now — the theme accent.
  now,

  /// Still ahead — informational blue.
  upcoming,

  /// Already passed — muted.
  past,

  /// An event that has already started — warning orange.
  started,
}

class TimeStatus {
  const TimeStatus(this.label, this.tone);

  final String label;
  final StatusTone tone;
}

/// The scheduled-lists rules.
///
/// Almost all of this feed's behaviour is client-side.
/// `GET /todo/lists/all-scheduled` returns two kinds of list unioned together:
/// **time-scheduled** lists (every non-archived list with a `scheduledTime`,
/// with no filtering whatsoever — not by day, not by time) and **event-linked**
/// lists (already windowed server-side and carrying a `linkedEvent`). Deciding
/// what to actually show is entirely up to the client.
///
/// These rules are ported from the Vue widget, not from the Kotlin
/// `TimeStatusEngine`. That engine is an earlier, different interpretation —
/// it treats "Now" as ±2 minutes rather than ±5, drops a list out of the active
/// section once it is more than 60 minutes past instead of keeping it for the
/// rest of the day, and uses different event wording. Following it would have
/// shipped behaviour that disagrees with the web app.
class ScheduledListRules {
  const ScheduledListRules._();

  /// A list counts as active from five minutes before its time, and stays
  /// active for the remainder of the day.
  static const int activeLeadMinutes = 5;

  /// Minutes from now until the list's scheduled time.
  ///
  /// Negative once the time has passed, which is what makes overdue lists sort
  /// to the top.
  static int? minutesUntilScheduled(TodoList list, DateTime now) {
    final scheduled = list.scheduledMinutes;
    if (scheduled == null) return null;
    return scheduled - (now.hour * 60 + now.minute);
  }

  /// Whether a list should appear in the feed at all today.
  ///
  /// Event-linked lists are always shown — the server already windowed them.
  /// Time-scheduled lists must pass the day-of-week filter, which the server
  /// applies on `/todo/lists/scheduled` but **not** on `/todo/lists/all-scheduled`.
  static bool isVisibleToday(TodoList list, DateTime now) {
    if (list.isEventLinked) return true;
    if (list.scheduledMinutes == null) return false;
    return list.runsOn(now);
  }

  /// Whether the list belongs in the "Active" section.
  static bool isActive(TodoList list, DateTime now) {
    if (!isVisibleToday(list, now)) return false;
    if (list.isEventLinked) return true;

    final until = minutesUntilScheduled(list, now);
    return until != null && until <= activeLeadMinutes;
  }

  /// Whether the list is a candidate for the "Up next" preview: time-scheduled
  /// and more than five minutes away.
  static bool isUpcoming(TodoList list, DateTime now) {
    if (list.isEventLinked) return false;
    if (!isVisibleToday(list, now)) return false;

    final until = minutesUntilScheduled(list, now);
    return until != null && until > activeLeadMinutes;
  }

  /// Splits the feed into the active section and the single "Up next" preview.
  static ({List<TodoList> active, TodoList? upNext}) classify(
    List<TodoList> lists,
    DateTime now,
  ) {
    final active = <TodoList>[];
    final upcoming = <TodoList>[];

    for (final list in lists) {
      if (isActive(list, now)) {
        active.add(list);
      } else if (isUpcoming(list, now)) {
        upcoming.add(list);
      }
    }

    // Signed minutes-to-scheduled ascending, so the most overdue sorts first.
    // Event-linked lists have no scheduled time; order them by event start.
    active.sort((a, b) => _sortKey(a, now).compareTo(_sortKey(b, now)));

    upcoming.sort(
      (a, b) => (minutesUntilScheduled(a, now) ?? 0)
          .compareTo(minutesUntilScheduled(b, now) ?? 0),
    );

    return (active: active, upNext: upcoming.isEmpty ? null : upcoming.first);
  }

  static int _sortKey(TodoList list, DateTime now) {
    final until = minutesUntilScheduled(list, now);
    if (until != null) return until;

    final event = list.linkedEvent;
    if (event != null) return event.eventStart.difference(now).inMinutes;
    return 1 << 30;
  }

  /// The status pill: label plus the tone it should be drawn in.
  static TimeStatus statusFor(TodoList list, DateTime now) {
    final event = list.linkedEvent;
    if (event != null) return _eventStatus(event, now);

    final until = minutesUntilScheduled(list, now);
    if (until == null) return const TimeStatus('', StatusTone.past);

    if (until.abs() <= activeLeadMinutes) {
      return const TimeStatus('Now', StatusTone.now);
    }
    if (until > 0) {
      return TimeStatus('In ${_duration(until)}', StatusTone.upcoming);
    }
    return TimeStatus('${_duration(-until)} ago', StatusTone.past);
  }

  static TimeStatus _eventStatus(LinkedEvent event, DateTime now) {
    final minutesToStart = event.eventStart.difference(now).inMinutes;

    if (minutesToStart <= 0) {
      final elapsed = -minutesToStart;
      if (elapsed < 60) {
        return const TimeStatus('Event started', StatusTone.started);
      }
      return TimeStatus('Started ${_duration(elapsed)} ago', StatusTone.started);
    }

    if (minutesToStart < 60) {
      return TimeStatus('Event in ${minutesToStart}m', StatusTone.now);
    }
    if (minutesToStart < 60 * 24) {
      return TimeStatus(
        'Event in ${minutesToStart ~/ 60}h',
        StatusTone.upcoming,
      );
    }

    final days = ApiDate.startOfDay(event.eventStart)
        .difference(ApiDate.startOfDay(now))
        .inDays;
    return TimeStatus(
      days <= 1 ? 'Tomorrow' : 'In $days days',
      StatusTone.past,
    );
  }

  /// `20 min` / `2h 5m` / `2h`, matching the web widget's phrasing.
  static String _duration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }

  /// Completed items sink to the bottom, preserving relative order otherwise.
  ///
  /// Applied independently to the ungrouped items and to each group, so a
  /// finished item never jumps out of its group.
  static List<TodoItem> completedLast(List<TodoItem> items) {
    final pending = items.where((item) => !item.isCompleted).toList();
    final done = items.where((item) => item.isCompleted).toList();
    return [...pending, ...done];
  }
}
