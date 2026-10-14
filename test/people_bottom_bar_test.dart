import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pham_dash_flutter/app/router.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/converters.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/features/dashboard/dashboard_shell.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';
import 'package:pham_dash_flutter/features/people/people_screen.dart';
import 'package:pham_dash_flutter/features/people/person_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _people = [
  Person(id: 'a1', firstName: 'Ha', lastName: 'Pham'),
  Person(id: 'b2', firstName: 'Minh', lastName: 'Pham'),
];

List<Relationship> _siblingsOf(String personId) => [
      for (final (index, person) in _people.indexed)
        if (person.id != personId)
          Relationship(
            relationshipId: index + 1,
            personId: personId,
            relatedPersonId: person.id,
            type: RelationshipType.sibling,
            relatedPersonFirstName: person.firstName,
            relatedPersonLastName: person.lastName,
          ),
    ];

/// The dashboard tabs stand in as plain pages at their real paths: the bar on
/// a people screen leaves by path, so the shell itself is not what is tested.
GoRouter _buildRouter() => GoRouter(
      initialLocation: DashboardTab.schedule.path,
      routes: [
        for (final tab in DashboardTab.values)
          GoRoute(
            path: tab.path,
            builder: (context, state) => Scaffold(
              body: Column(
                children: [
                  Text('${tab.label} tab'),
                  TextButton(
                    onPressed: () => context.push(peopleListLocation),
                    child: const Text('Open People'),
                  ),
                ],
              ),
            ),
          ),
        GoRoute(
          path: peopleListLocation,
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

Future<void> _pumpPeopleList(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        allPeopleProvider.overrideWithBuild((ref, _) => _people),
        personTagsProvider.overrideWithBuild((ref, _) => const <PersonTag>[]),
        allNotesProvider.overrideWithBuild((ref, _) => const <Note>[]),
        allRelationshipsProvider.overrideWithBuild(
          (ref, _) => const <Relationship>[],
        ),
        personProvider.overrideWith(
          (ref, id) => _people.firstWhere((person) => person.id == id),
        ),
        personRelationshipsProvider.overrideWith(
          (ref, id) => _siblingsOf(id),
        ),
        personNotesProvider.overrideWith((ref, id) => const <Note>[]),
      ],
      child: MaterialApp.router(routerConfig: _buildRouter()),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Open People'));
  await tester.pumpAndSettle();
}

Finder _barButton(String label) => find.descendant(
      of: find.byType(DashboardBottomBar),
      matching: find.byTooltip(label),
    );

void main() {
  testWidgets('the people list shows the bar, with back still in the app bar',
      (tester) async {
    await _pumpPeopleList(tester);

    for (final tab in DashboardTab.values) {
      expect(_barButton(tab.label), findsOneWidget);
    }
    expect(_barButton('People'), findsOneWidget);
    // The drawer the Menu button needs must not take the back arrow's place.
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byType(DrawerButton), findsNothing);
  });

  testWidgets('a tab in the bar leaves People for that tab', (tester) async {
    await _pumpPeopleList(tester);

    await tester.tap(_barButton('Lists'));
    await tester.pumpAndSettle();

    expect(find.text('Lists tab'), findsOneWidget);
    expect(find.byType(PeopleScreen), findsNothing);
  });

  testWidgets('person pages show the bar too', (tester) async {
    await _pumpPeopleList(tester);

    await tester.tap(find.text('Ha Pham'));
    await tester.pumpAndSettle();

    expect(find.byType(PersonDetailScreen), findsOneWidget);
    expect(_barButton('Notes'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('People in the bar drops a person chain back to the one list',
      (tester) async {
    await _pumpPeopleList(tester);

    await tester.tap(find.text('Ha Pham'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Minh Pham'));
    await tester.pumpAndSettle();

    await tester.tap(_barButton('People'));
    await tester.pumpAndSettle();

    expect(find.byType(PersonDetailScreen, skipOffstage: false), findsNothing);
    // Popped back to, not pushed a second time.
    expect(find.byType(PeopleScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('People in the bar does nothing on the list itself',
      (tester) async {
    await _pumpPeopleList(tester);

    await tester.tap(_barButton('People'));
    await tester.pumpAndSettle();

    expect(find.byType(PeopleScreen, skipOffstage: false), findsOneWidget);

    // And the tab it was opened from is still beneath it.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Schedule tab'), findsOneWidget);
  });
}
