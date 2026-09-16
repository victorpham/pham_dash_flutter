/// Date handling for the PhamDash API.
///
/// The API is ASP.NET Core, and .NET serializes a `DateTime` with **no timezone
/// marker** unless its `Kind` is `Utc`. Values that have round-tripped through
/// SQL Server come back as `Unspecified`, so nearly every timestamp looks like
/// `2026-09-04T18:30:00` — no `Z`, no offset.
///
/// Two different meanings hide behind that one shape, and mixing them up shifts
/// every event by the device's UTC offset:
///
///  * **Wall clock** — `calendarEvent.start` / `end`, `person.birthDate`,
///    `todoList.reminderDateTime`. These are literal clock readings in the
///    calendar's own timezone. Parse the components and render them as-is.
///  * **UTC instants** — `createdAt`, `updatedAt`, `completedAt`. Written as
///    `DateTime.UtcNow` server-side, so they *are* UTC despite the missing `Z`.
///    `syncStatus.lastSyncedAt` is the one field explicitly stamped `Utc` and so
///    does carry a `Z`.
///
/// The Vue client gets this wrong: it parses offset-less strings as device-local
/// and then formats them in a hardcoded `America/Los_Angeles`, which shifts
/// displayed times on any device outside Pacific. Rendering wall-clock
/// components directly, as below, is correct in every timezone.
library;

/// Matches a trailing `Z` or a `+HH:MM` / `-HH:MM` UTC offset.
final RegExp _trailingZone = RegExp(r'(?:Z|[+-]\d{2}:?\d{2})$');

class ApiDate {
  const ApiDate._();

  /// Parses a wall-clock timestamp, preserving the literal clock components.
  ///
  /// Any timezone suffix is stripped first so the result never shifts: a
  /// calendar event at 18:30 reads 18:30 on every device.
  static DateTime? wallClock(String? value) {
    if (value == null || value.isEmpty) return null;
    final stripped = value.replaceFirst(_trailingZone, '');
    return DateTime.tryParse(stripped);
  }

  /// Parses a UTC instant that may be missing its `Z`, returned in local time.
  static DateTime? utcStamp(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized =
        _trailingZone.hasMatch(value) ? value : '${value}Z';
    return DateTime.tryParse(normalized)?.toLocal();
  }

  /// Serializes a wall-clock value the way the API expects it: no zone marker.
  static String formatWallClock(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}-${two(value.month)}-'
        '${two(value.day)}T${two(value.hour)}:${two(value.minute)}:'
        '${two(value.second)}';
  }

  /// Serializes a `timeMin` / `timeMax` query parameter.
  ///
  /// The web client sends `toISOString()` (UTC with `Z`) and the server compares
  /// it against stored wall-clock values, so we match that exactly.
  static String formatQueryInstant(DateTime value) =>
      value.toUtc().toIso8601String();

  /// Parses `todoList.scheduledTime`, which is a `"HH:mm"` **string**, not a
  /// timestamp. Returns minutes since midnight, or null if unparseable.
  static int? parseMinutesOfDay(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  /// Formats minutes since midnight back into the `"HH:mm"` the API expects.
  static String formatMinutesOfDay(int minutesOfDay) {
    final h = (minutesOfDay ~/ 60).toString().padLeft(2, '0');
    final m = (minutesOfDay % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Parses `todoList.scheduledDays`, a CSV of `0`=Sunday .. `6`=Saturday.
  /// An empty or null value means "every day" and yields an empty set.
  static Set<int> parseScheduledDays(String? csv) {
    if (csv == null || csv.trim().isEmpty) return const {};
    return csv
        .split(',')
        .map((part) => int.tryParse(part.trim()))
        .whereType<int>()
        .where((day) => day >= 0 && day <= 6)
        .toSet();
  }

  static String? formatScheduledDays(Set<int> days) {
    if (days.isEmpty) return null;
    final sorted = days.toList()..sort();
    return sorted.join(',');
  }

  /// Dart's [DateTime.weekday] is 1=Monday..7=Sunday; the API's `scheduledDays`
  /// uses JavaScript's 0=Sunday..6=Saturday. This converts between them.
  static int jsWeekday(DateTime date) => date.weekday % 7;

  /// Midnight local time on the same calendar day as [date].
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// True when the two values fall on the same local calendar day.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
