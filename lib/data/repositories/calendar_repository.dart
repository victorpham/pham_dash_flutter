import '../../core/api/api_client.dart';
import '../../core/api/api_date.dart';
import '../models/calendar_models.dart';
import '../models/converters.dart';
import 'decode.dart';

/// Calendar events and the local metadata layered on top of them.
///
/// Events themselves are **read-only**: Google Calendar is the source of truth
/// and there is no create/edit/delete endpoint. Everything writable here is
/// PhamDash's own enrichment - attendees, notes, tags, categories and linked
/// todo lists.
///
/// Be aware of the sync behaviour behind every read: the API does not query
/// Google per request, but each `GET /calendar/events*` checks the last sync
/// time and, if it is older than 15 minutes, runs a **full sync inline before
/// responding**. The first call after an idle period is therefore slow, which
/// is why `ApiClient` uses a 60s read timeout. If Google Calendar is not
/// configured at all the API logs a warning and returns empty lists rather than
/// failing, so an empty calendar is not necessarily a client bug.
class CalendarRepository {
  const CalendarRepository(this._api);

  final ApiClient _api;

  /// Events overlapping the given range.
  ///
  /// Filtering is inclusive-overlap (`End >= timeMin && Start <= timeMax`),
  /// ordered by start. Hidden, soft-deleted and cancelled events are excluded
  /// server-side.
  Future<List<CalendarEvent>> events({
    required DateTime timeMin,
    required DateTime timeMax,
    int? maxResults,
  }) async {
    final data = await _api.get<dynamic>(
      '/calendar/events',
      query: {
        'timeMin': ApiDate.formatQueryInstant(timeMin),
        'timeMax': ApiDate.formatQueryInstant(timeMax),
        'maxResults': ?maxResults,
      },
    );
    return decodeList(data, CalendarEvent.fromJson);
  }

  Future<List<CalendarEvent>> today() async =>
      decodeList(await _api.get<dynamic>('/calendar/events/today'),
          CalendarEvent.fromJson);

  Future<List<CalendarEvent>> week() async =>
      decodeList(await _api.get<dynamic>('/calendar/events/week'),
          CalendarEvent.fromJson);

  Future<List<CalendarEvent>> month() async =>
      decodeList(await _api.get<dynamic>('/calendar/events/month'),
          CalendarEvent.fromJson);

  /// Events a person is an attendee of. Returned **without** attendees or
  /// categories populated.
  Future<List<CalendarEvent>> eventsForPerson(String personId) async =>
      decodeList(
        await _api.get<dynamic>('/calendar/person/$personId/events'),
        CalendarEvent.fromJson,
      );

  /// Forces an immediate sync, bypassing the 15-minute interval.
  /// This is what pull-to-refresh should call.
  Future<void> sync() => _api.post<dynamic>('/calendar/sync');

  Future<CalendarSyncStatus> syncStatus() async {
    final data = await _api.get<dynamic>('/calendar/sync/status');
    return decodeOrNull(data, CalendarSyncStatus.fromJson) ??
        const CalendarSyncStatus();
  }

  // --- Attendees -----------------------------------------------------------

  Future<List<CalendarEventAttendee>> attendees(String eventId) async =>
      decodeList(
        await _api.get<dynamic>('/calendar/events/$eventId/attendees'),
        CalendarEventAttendee.fromJson,
      );

  /// Links a person to an event.
  ///
  /// Throws an [ApiException] with `isConflict` when the person is already an
  /// attendee - worth surfacing inline rather than as a generic failure.
  Future<CalendarEventAttendee?> addAttendee(
    String eventId, {
    required String personId,
    AttendanceStatus? status,
    String? notes,
  }) async {
    final data = await _api.post<dynamic>(
      '/calendar/events/$eventId/attendees',
      body: {
        'personId': personId,
        if (status != null) 'status': status.wireValue,
        'notes': ?notes,
      },
    );
    return decodeOrNull(data, CalendarEventAttendee.fromJson);
  }

  Future<CalendarEventAttendee?> updateAttendee(
    String eventId,
    int attendeeId, {
    AttendanceStatus? status,
    String? notes,
  }) async {
    final data = await _api.put<dynamic>(
      '/calendar/events/$eventId/attendees/$attendeeId',
      body: {
        if (status != null) 'status': status.wireValue,
        'notes': ?notes,
      },
    );
    return decodeOrNull(data, CalendarEventAttendee.fromJson);
  }

  Future<void> removeAttendee(String eventId, int attendeeId) =>
      _api.delete('/calendar/events/$eventId/attendees/$attendeeId');

  /// The "who am I about to meet" payload: age, three most recent notes and
  /// immediate family per attendee, in a single call.
  Future<List<AttendeeSummary>> attendeeSummary(String eventId) async =>
      decodeList(
        await _api.get<dynamic>('/calendar/events/$eventId/summary'),
        AttendeeSummary.fromJson,
      );

  // --- Event notes ---------------------------------------------------------

  Future<List<EventNote>> notes(String eventId) async => decodeList(
        await _api.get<dynamic>('/calendar/events/$eventId/notes'),
        EventNote.fromJson,
      );

  Future<EventNote?> addNote(String eventId, String content) async =>
      decodeOrNull(
        await _api.post<dynamic>(
          '/calendar/events/$eventId/notes',
          body: {'content': content},
        ),
        EventNote.fromJson,
      );

  Future<EventNote?> updateNote(
    String eventId,
    int noteId,
    String content,
  ) async =>
      decodeOrNull(
        await _api.put<dynamic>(
          '/calendar/events/$eventId/notes/$noteId',
          body: {'content': content},
        ),
        EventNote.fromJson,
      );

  Future<void> deleteNote(String eventId, int noteId) =>
      _api.delete('/calendar/events/$eventId/notes/$noteId');

  // --- Tags ----------------------------------------------------------------

  Future<List<EventTag>> tags(String eventId) async => decodeList(
        await _api.get<dynamic>('/calendar/events/$eventId/tags'),
        EventTag.fromJson,
      );

  Future<EventTag?> addTag(String eventId, String tag, {String? color}) async =>
      decodeOrNull(
        await _api.post<dynamic>(
          '/calendar/events/$eventId/tags',
          body: {'tag': tag, 'color': ?color},
        ),
        EventTag.fromJson,
      );

  Future<void> deleteTag(String eventId, int tagId) =>
      _api.delete('/calendar/events/$eventId/tags/$tagId');

  // --- Categories ----------------------------------------------------------

  Future<List<EventCategory>> eventCategories(String eventId) async =>
      decodeList(
        await _api.get<dynamic>('/calendar/events/$eventId/categories'),
        EventCategory.fromJson,
      );

  /// Conflicts (409) when the category is already assigned.
  Future<void> assignCategory(String eventId, int categoryId) =>
      _api.post<dynamic>('/calendar/events/$eventId/categories/$categoryId');

  Future<void> unassignCategory(String eventId, int categoryId) =>
      _api.delete('/calendar/events/$eventId/categories/$categoryId');

  // --- Linked todo lists ---------------------------------------------------

  Future<List<LinkedTodoList>> linkedLists(String eventId) async => decodeList(
        await _api.get<dynamic>('/calendar/events/$eventId/lists'),
        LinkedTodoList.fromJson,
      );

  /// Linking a list to an event is what makes it surface in the scheduled-lists
  /// feed ahead of that event.
  Future<void> linkList(String eventId, int listId) =>
      _api.post<dynamic>('/calendar/events/$eventId/lists/$listId');

  Future<void> unlinkList(String eventId, int listId) =>
      _api.delete('/calendar/events/$eventId/lists/$listId');
}

/// `GET /api/event-categories` - the user's own category vocabulary.
class EventCategoryRepository {
  const EventCategoryRepository(this._api);

  final ApiClient _api;

  Future<List<EventCategory>> all() async => decodeList(
        await _api.get<dynamic>('/event-categories'),
        EventCategory.fromJson,
      );

  /// Names are unique per user; a duplicate returns 409. `color` is validated
  /// against `^#[0-9A-Fa-f]{6}$` and an invalid value returns an ASP.NET
  /// validation-problem body rather than the usual `{message, statusCode}`.
  Future<EventCategory?> create(String name, {String? color}) async =>
      decodeOrNull(
        await _api.post<dynamic>(
          '/event-categories',
          body: {'name': name, 'color': ?color},
        ),
        EventCategory.fromJson,
      );

  Future<EventCategory?> update(int id, {String? name, String? color}) async =>
      decodeOrNull(
        await _api.put<dynamic>(
          '/event-categories/$id',
          body: {
            'name': ?name,
            'color': ?color,
          },
        ),
        EventCategory.fromJson,
      );

  Future<void> delete(int id) => _api.delete('/event-categories/$id');
}
