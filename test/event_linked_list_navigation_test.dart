import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pham_dash_flutter/data/models/calendar_models.dart';
import 'package:pham_dash_flutter/features/calendar/event_detail_sheet.dart';
import 'package:pham_dash_flutter/features/calendar/event_providers.dart';

const _eventId = 'evt-1';

final _event = CalendarEvent(
  id: _eventId,
  title: 'Flight to SF',
  start: DateTime(2026, 9, 20, 8),
  end: DateTime(2026, 9, 20, 11),
  isAllDay: false,
  attendees: const [],
  categories: const [],
);

const _packing = LinkedTodoList(
  id: 11,
  title: 'Packing',
  isPinned: false,
  itemCount: 12,
);

/// The event sheet plus a stub for the route it pushes into.
GoRouter _buildRouter() => GoRouter(
      initialLocation: '/event',
      routes: [
        GoRoute(
          path: '/event',
          builder: (context, state) => Scaffold(
            body: EventDetailSheet(
              event: _event,
              scrollController: ScrollController(),
            ),
          ),
        ),
        GoRoute(
          path: '/todo/:id',
          builder: (context, state) => Scaffold(
            body: Text('list ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );

/// Every section of the sheet is overridden, not just the linked lists: left
/// alone they would reach for a real `ApiClient`.
Future<void> _pumpSheet(
  WidgetTester tester, {
  List<LinkedTodoList> linked = const [_packing],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        eventLinkedListsProvider.overrideWith((ref, id) => linked),
        eventAttendeesProvider.overrideWith(
          (ref, id) => const <CalendarEventAttendee>[],
        ),
        eventNotesProvider.overrideWith((ref, id) => const <EventNote>[]),
        eventTagsProvider.overrideWith((ref, id) => const <EventTag>[]),
        eventCategoriesProvider.overrideWith(
          (ref, id) => const <EventCategory>[],
        ),
        eventSummaryProvider.overrideWith(
          (ref, id) => const <AttendeeSummary>[],
        ),
      ],
      child: MaterialApp.router(routerConfig: _buildRouter()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // The Lists tab used to carry event-linked lists itself, ahead of the event,
  // and was the only way to open one. It is the full list browser now, so this
  // row is the route from an event to its list - if it stops navigating, a
  // packing list becomes unreachable from the event that needs it.
  testWidgets('tapping a linked list opens it', (tester) async {
    await _pumpSheet(tester);

    expect(find.text('Packing'), findsOneWidget);
    expect(find.text('12 items'), findsOneWidget);

    await tester.tap(find.text('Packing'));
    await tester.pumpAndSettle();

    expect(find.text('list 11'), findsOneWidget);
  });

  testWidgets('the empty state no longer promises the Lists tab',
      (tester) async {
    await _pumpSheet(tester, linked: const []);

    expect(find.textContaining('Lists tab'), findsNothing);
    expect(find.textContaining('No lists linked'), findsOneWidget);
  });
}
