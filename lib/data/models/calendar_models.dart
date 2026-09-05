import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';

part 'calendar_models.freezed.dart';
part 'calendar_models.g.dart';

/// A category chip on an event, e.g. `Con` (#8800FF) or `Crystal` (#FF0092).
///
/// The API auto-assigns these after each sync when an event title contains the
/// whole word `Con` or `Crystal`, creating the category if it does not exist.
@freezed
abstract class EventCategory with _$EventCategory {
  const factory EventCategory({
    required int id,
    required String name,
    String? color,
  }) = _EventCategory;

  factory EventCategory.fromJson(Map<String, dynamic> json) =>
      _$EventCategoryFromJson(json);
}

/// The trimmed attendee shape embedded in a calendar event.
///
/// Distinct from [CalendarEventAttendee], which is what the attendee metadata
/// endpoints return.
@freezed
abstract class EventAttendeeRef with _$EventAttendeeRef {
  const factory EventAttendeeRef({
    required String personId,
    required String name,
    String? profilePictureUrl,
  }) = _EventAttendeeRef;

  factory EventAttendeeRef.fromJson(Map<String, dynamic> json) =>
      _$EventAttendeeRefFromJson(json);
}

/// An event synced from Google Calendar.
///
/// **Read-only.** Google is the source of truth and the API exposes no create,
/// edit or delete endpoint; all local enrichment happens through the separate
/// metadata endpoints (attendees, notes, tags, categories, linked lists).
@freezed
abstract class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent({
    required String id,
    required String title,

    /// May contain HTML pasted in from Google. Strip it before display.
    String? description,
    String? location,

    /// Wall-clock time in the calendar's own timezone - display as-is.
    @RequiredWallClock() required DateTime start,
    @RequiredWallClock() required DateTime end,

    /// All-day events carry a `start` of midnight.
    @JsonKey(defaultValue: false) required bool isAllDay,
    String? htmlLink,

    /// `confirmed` | `tentative` | `cancelled`. Cancelled events are already
    /// excluded server-side.
    String? status,
    @JsonKey(defaultValue: <EventAttendeeRef>[])
    required List<EventAttendeeRef> attendees,
    @JsonKey(defaultValue: <EventCategory>[])
    required List<EventCategory> categories,
  }) = _CalendarEvent;

  const CalendarEvent._();

  factory CalendarEvent.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventFromJson(json);

  /// The accent colour for this event, as a hex string.
  ///
  /// The web client uses the first category that actually has a colour, falling
  /// back to the theme primary; all-day events always use the primary. Returns
  /// null to mean "use the theme primary".
  String? get accentColorHex {
    if (isAllDay) return null;
    for (final category in categories) {
      final color = category.color;
      if (color != null && color.isNotEmpty) return color;
    }
    return null;
  }
}

/// `GET /api/calendar/sync/status`.
@freezed
abstract class CalendarSyncStatus with _$CalendarSyncStatus {
  const factory CalendarSyncStatus({
    /// The one timestamp in the API explicitly stamped `DateTimeKind.Utc`, so
    /// it does arrive with a `Z`.
    @UtcStamp() DateTime? lastSyncedAt,
  }) = _CalendarSyncStatus;

  factory CalendarSyncStatus.fromJson(Map<String, dynamic> json) =>
      _$CalendarSyncStatusFromJson(json);
}

/// A person linked to an event through the attendee metadata endpoints.
@freezed
abstract class CalendarEventAttendee with _$CalendarEventAttendee {
  const factory CalendarEventAttendee({
    required int id,
    required String calendarEventId,
    required String personId,
    String? personName,
    String? personProfilePictureUrl,
    @AttendanceStatusConverter()
    @JsonKey(name: 'status')
    required AttendanceStatus status,
    String? notes,
  }) = _CalendarEventAttendee;

  factory CalendarEventAttendee.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventAttendeeFromJson(json);
}

/// One of the three most recent notes carried by [AttendeeSummary].
@freezed
abstract class AttendeeRecentNote with _$AttendeeRecentNote {
  const factory AttendeeRecentNote({
    required String content,
    @UtcStamp() DateTime? createdAt,
  }) = _AttendeeRecentNote;

  factory AttendeeRecentNote.fromJson(Map<String, dynamic> json) =>
      _$AttendeeRecentNoteFromJson(json);
}

/// `GET /api/calendar/events/{id}/summary` - a purpose-built
/// "who am I about to meet" payload that replaces several round trips.
@freezed
abstract class AttendeeSummary with _$AttendeeSummary {
  const factory AttendeeSummary({
    required String personId,
    required String name,
    String? profilePictureUrl,
    int? age,
    @JsonKey(defaultValue: <AttendeeRecentNote>[])
    required List<AttendeeRecentNote> recentNotes,

    /// Pre-formatted `"Name (Type)"` strings, spouse/sibling/parent/child only
    /// - friends are excluded server-side.
    @JsonKey(defaultValue: <String>[]) required List<String> immediateFamily,
  }) = _AttendeeSummary;

  factory AttendeeSummary.fromJson(Map<String, dynamic> json) =>
      _$AttendeeSummaryFromJson(json);
}

/// A note attached to an event, distinct from a note attached to a person.
@freezed
abstract class EventNote with _$EventNote {
  const factory EventNote({
    required int id,
    required String calendarEventId,
    required String content,
    @UtcStamp() DateTime? createdAt,
    @UtcStamp() DateTime? updatedAt,
  }) = _EventNote;

  factory EventNote.fromJson(Map<String, dynamic> json) =>
      _$EventNoteFromJson(json);
}

@freezed
abstract class EventTag with _$EventTag {
  const factory EventTag({
    required int id,
    required String calendarEventId,
    required String tag,
    String? color,
  }) = _EventTag;

  factory EventTag.fromJson(Map<String, dynamic> json) =>
      _$EventTagFromJson(json);
}

/// The reduced todo-list shape returned by
/// `GET /api/calendar/events/{id}/lists`.
@freezed
abstract class LinkedTodoList with _$LinkedTodoList {
  const factory LinkedTodoList({
    required int id,
    required String title,
    String? color,
    @JsonKey(defaultValue: false) required bool isPinned,
    @JsonKey(defaultValue: 0) required int itemCount,
  }) = _LinkedTodoList;

  factory LinkedTodoList.fromJson(Map<String, dynamic> json) =>
      _$LinkedTodoListFromJson(json);
}
