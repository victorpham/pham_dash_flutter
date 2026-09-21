import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/api/api_exception.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/data/repositories/people_repository.dart';
import 'package:pham_dash_flutter/features/people/pending_creates.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';
import 'package:pham_dash_flutter/features/people/people_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The People list while a person is still on their way to the server.

const _people = [Person(id: 'a1', firstName: 'Ha', lastName: 'Pham')];

class _FakePeople extends PeopleRepository {
  _FakePeople(super.api);

  Completer<void>? gate;
  Object? failWith;

  @override
  Future<Person?> create({
    required String firstName,
    required String lastName,
    String? vietnameseName,
    String? homeAddress,
    DateTime? birthDate,
  }) async {
    await gate?.future;
    if (failWith case final error?) throw error;
    return Person(id: 'real1', firstName: firstName, lastName: lastName);
  }
}

Future<({ProviderContainer container, _FakePeople people, List<String> pushed})>
_pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final people = _FakePeople(ApiClient(AuthService()));

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      peopleRepositoryProvider.overrideWithValue(people),
      allPeopleProvider.overrideWithBuild((ref, _) => _people),
      personTagsProvider.overrideWithBuild((ref, _) => const <PersonTag>[]),
      allNotesProvider.overrideWithBuild((ref, _) => const <Note>[]),
      allRelationshipsProvider.overrideWithBuild(
        (ref, _) => const <Relationship>[],
      ),
    ],
  );
  addTearDown(container.dispose);

  final pushed = <String>[];
  final router = GoRouter(
    initialLocation: '/people',
    routes: [
      GoRoute(path: '/people', builder: (_, _) => const PeopleScreen()),
      GoRoute(
        path: '/people/:id',
        builder: (_, state) {
          pushed.add(state.pathParameters['id']!);
          return const Scaffold(body: Text('Detail'));
        },
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return (container: container, people: people, pushed: pushed);
}

void main() {
  testWidgets('a queued person is a row at once, without a menu, and opens '
      'their placeholder page', (tester) async {
    final h = await _pump(tester);
    h.people.gate = Completer<void>();
    final placeholder = h.container
        .read(pendingCreatesProvider.notifier)
        .addPerson(firstName: 'Ada', lastName: 'Lovelace');
    await tester.pump();

    final row = find.widgetWithText(ListTile, 'Ada Lovelace');
    expect(row, findsOneWidget);
    expect(find.byKey(const ValueKey('pending-saving')), findsOneWidget);
    // The fetched row keeps its menu; the placeholder has nothing to edit.
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    // The app-bar glyph says a write is out.
    expect(find.byKey(const ValueKey('sync-in-flight')), findsOneWidget);

    await tester.tap(row);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(h.pushed, [placeholder.id]);
  });

  testWidgets('a failed person shows the failure inline and the glyph turns '
      'red; Discard removes the row', (tester) async {
    final h = await _pump(tester);
    h.people.failWith = const NetworkException('Server asleep');
    h.container
        .read(pendingCreatesProvider.notifier)
        .addPerson(firstName: 'Ada', lastName: 'Lovelace');
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('pending-failed')), findsOneWidget);
    expect(find.textContaining('Server asleep'), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-failed')), findsOneWidget);

    // The glyph opens the sheet listing what failed.
    await tester.tap(find.byKey(const ValueKey('sync-failed')));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t save 1 change'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Ada Lovelace'), findsNothing);
    expect(find.byKey(const ValueKey('sync-failed')), findsNothing);
    expect(find.text('Ha Pham'), findsOneWidget);
  });

  testWidgets(
    'the placeholder row gives way to the fetched one without a gap',
    (tester) async {
      final h = await _pump(tester);
      h.people.gate = Completer<void>();
      h.container
          .read(pendingCreatesProvider.notifier)
          .addPerson(firstName: 'Ada', lastName: 'Lovelace');
      await tester.pump();

      h.people.gate!.complete();
      await tester.pump();
      await tester.pump();

      // Landed, but the directory has not been re-read yet: still one row, now
      // an ordinary one.
      expect(find.widgetWithText(ListTile, 'Ada Lovelace'), findsOneWidget);
      expect(find.byKey(const ValueKey('pending-saving')), findsNothing);
    },
  );
}
