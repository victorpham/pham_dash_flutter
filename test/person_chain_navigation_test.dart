import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pham_dash_flutter/app/router.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/converters.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';
import 'package:pham_dash_flutter/features/people/people_screen.dart';
import 'package:pham_dash_flutter/features/people/person_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _people = [
  Person(id: 'a1', firstName: 'Ha', lastName: 'Pham'),
  Person(id: 'b2', firstName: 'Minh', lastName: 'Pham'),
  Person(id: 'c3', firstName: 'Lan', lastName: 'Pham'),
];

/// Everyone is a sibling of everyone else, so any person page offers a row
/// leading to the next one and a chain can be walked as deep as needed.
List<Relationship> _siblingsOf(String personId) {
  var id = 0;
  return [
    for (final person in _people)
      if (person.id != personId)
        Relationship(
          relationshipId: ++id,
          personId: personId,
          relatedPersonId: person.id,
          type: RelationshipType.sibling,
          relatedPersonFirstName: person.firstName,
          relatedPersonLastName: person.lastName,
        ),
  ];
}

/// The real app routes, trimmed to the two this test drives. Using the same
/// `personPageName` the app does is the point — the escape hatch pops by name.
GoRouter _buildRouter(String initialLocation) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Dashboard')),
            body: TextButton(
              onPressed: () => context.push('/people/a1'),
              child: const Text('Open Ha from a birthday row'),
            ),
          ),
        ),
        GoRoute(
          path: '/people',
          builder: (context, state) => const PeopleScreen(),
        ),
        GoRoute(
          path: '/people/:id',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            name: personPageName,
            child: PersonDetailScreen(personId: state.pathParameters['id']!),
          ),
        ),
      ],
    );

Future<void> _pump(
  WidgetTester tester, {
  required String initialLocation,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        allPeopleProvider.overrideWith((ref) => _people),
        personProvider.overrideWith(
          (ref, id) => _people.firstWhere((person) => person.id == id),
        ),
        personRelationshipsProvider.overrideWith(
          (ref, id) => _siblingsOf(id),
        ),
        personNotesProvider.overrideWith((ref, id) => const <Note>[]),
      ],
      child: MaterialApp.router(routerConfig: _buildRouter(initialLocation)),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _backToList() =>
    find.widgetWithIcon(IconButton, Icons.people_alt_outlined);

/// Follows a sibling row from the person page currently on top.
Future<void> _followRelationship(WidgetTester tester, String name) async {
  await tester.tap(find.widgetWithText(ListTile, name));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the escape hatch stays hidden on the first person page',
      (tester) async {
    await _pump(tester, initialLocation: '/people');

    await tester.tap(find.text('Ha Pham'));
    await tester.pumpAndSettle();

    // Back alone already reaches the list from here.
    expect(_backToList(), findsNothing);
  });

  testWidgets('one tap returns to the list from deep in a chain',
      (tester) async {
    await _pump(tester, initialLocation: '/people');

    await tester.tap(find.text('Ha Pham'));
    await tester.pumpAndSettle();
    await _followRelationship(tester, 'Minh Pham');
    await _followRelationship(tester, 'Lan Pham');
    await _followRelationship(tester, 'Ha Pham');

    expect(_backToList(), findsOneWidget);

    await tester.tap(_backToList());
    await tester.pumpAndSettle();

    // The list itself, not another person page.
    expect(find.text('People'), findsOneWidget);
    expect(find.byType(PersonDetailScreen), findsNothing);
  });

  testWidgets('the pages below the chain survive, so back still works',
      (tester) async {
    await _pump(tester, initialLocation: '/home');

    await tester.tap(find.text('Open Ha from a birthday row'));
    await tester.pumpAndSettle();
    await _followRelationship(tester, 'Minh Pham');

    await tester.tap(_backToList());
    await tester.pumpAndSettle();

    // A chain begun at a birthday row has no list beneath it, so one is pushed.
    expect(find.text('People'), findsOneWidget);

    // And the dashboard it started from is still there to go back to.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('ordinary back still steps through the chain one at a time',
      (tester) async {
    await _pump(tester, initialLocation: '/people');

    await tester.tap(find.text('Ha Pham'));
    await tester.pumpAndSettle();
    await _followRelationship(tester, 'Minh Pham');
    await _followRelationship(tester, 'Lan Pham');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Minh Pham'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Ha Pham'), findsOneWidget);
  });
}
