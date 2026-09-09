import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/calendar_models.dart';

/// Per-event metadata. All keyed by the Google event id.
///
/// These are `autoDispose` and family-scoped so closing an event's sheet
/// releases its data rather than accumulating every event ever opened.

final eventSummaryProvider =
    FutureProvider.autoDispose.family<List<AttendeeSummary>, String>(
  (ref, eventId) =>
      ref.watch(calendarRepositoryProvider).attendeeSummary(eventId),
);

final eventAttendeesProvider =
    FutureProvider.autoDispose.family<List<CalendarEventAttendee>, String>(
  (ref, eventId) => ref.watch(calendarRepositoryProvider).attendees(eventId),
);

final eventNotesProvider =
    FutureProvider.autoDispose.family<List<EventNote>, String>(
  (ref, eventId) => ref.watch(calendarRepositoryProvider).notes(eventId),
);

final eventTagsProvider =
    FutureProvider.autoDispose.family<List<EventTag>, String>(
  (ref, eventId) => ref.watch(calendarRepositoryProvider).tags(eventId),
);

final eventCategoriesProvider =
    FutureProvider.autoDispose.family<List<EventCategory>, String>(
  (ref, eventId) =>
      ref.watch(calendarRepositoryProvider).eventCategories(eventId),
);

final eventLinkedListsProvider =
    FutureProvider.autoDispose.family<List<LinkedTodoList>, String>(
  (ref, eventId) => ref.watch(calendarRepositoryProvider).linkedLists(eventId),
);

/// The user's whole category vocabulary, for the assign picker.
final allEventCategoriesProvider =
    FutureProvider.autoDispose<List<EventCategory>>(
  (ref) => ref.watch(eventCategoryRepositoryProvider).all(),
);
