import 'package:intl/intl.dart';

import '../../core/api/api_date.dart';
import '../../data/models/calendar_models.dart';

/// Formatting and filtering shared by the schedule tab, the calendar grid and
/// the full calendar screen.
class EventUtils {
  const EventUtils._();

  /// The personal filter the web app hardcodes in the schedule widget and
  /// exposes as a `hideTuMeetings` toggle on the calendar page.
  ///
  /// Matches titles **containing** `Tu: Meeting`. (The Kotlin app filters on
  /// `startsWith("Tu:")` instead, which also hides unrelated `Tu:` events.)
  static const String tuMeetingMarker = 'Tu: Meeting';

  static List<CalendarEvent> hideTuMeetings(
    List<CalendarEvent> events, {
    bool hide = true,
  }) {
    if (!hide) return events;
    return events
        .where(
          (event) => !event.title.toLowerCase().contains(
                tuMeetingMarker.toLowerCase(),
              ),
        )
        .toList();
  }

  /// Google event descriptions can contain HTML. The web client strips tags
  /// before display; we do the same rather than rendering markup we did not
  /// author.
  static String? stripHtml(String? html) {
    if (html == null || html.isEmpty) return null;
    final text = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
    return text.isEmpty ? null : text;
  }

  /// `Today` / `Tomorrow` / `Wednesday, Sep 9`, as the schedule widget's date
  /// headers read.
  static String dateHeader(DateTime day, {DateTime? now}) {
    final today = ApiDate.startOfDay(now ?? DateTime.now());
    final target = ApiDate.startOfDay(day);
    final difference = target.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    return DateFormat('EEEE, MMM d').format(day);
  }

  /// `2:30 PM`, or `All day` for an all-day event.
  static String timeRange(CalendarEvent event) {
    if (event.isAllDay) return 'All day';
    final format = DateFormat('h:mm a');
    final start = format.format(event.start);
    // A zero-length event reads better as a single time than as "2:30 PM - 2:30 PM".
    if (event.end == event.start) return start;
    return '$start - ${format.format(event.end)}';
  }

  static String time(DateTime value) => DateFormat('h:mm a').format(value);

  /// Groups events by local calendar day, preserving the API's start ordering.
  static Map<DateTime, List<CalendarEvent>> groupByDay(
    List<CalendarEvent> events,
  ) {
    final grouped = <DateTime, List<CalendarEvent>>{};
    for (final event in events) {
      grouped.putIfAbsent(ApiDate.startOfDay(event.start), () => []).add(event);
    }

    final ordered = grouped.keys.toList()..sort();
    return {for (final day in ordered) day: grouped[day]!};
  }

  /// A relative "3 days ago" style stamp for note and sync timestamps.
  static String relative(DateTime value, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final difference = reference.difference(value);

    if (difference.isNegative) return DateFormat('MMM d').format(value);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d').format(value);
  }
}
