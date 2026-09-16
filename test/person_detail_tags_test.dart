import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pham_dash_flutter/app/router.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';
import 'package:pham_dash_flutter/features/people/person_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pickleball = PersonTag(id: 1, name: 'Pickleball Friends', personCount: 2);
const _coworkers = PersonTag(id: 2, name: 'Coworkers', personCount: 1);

/// Every other section is overridden empty, so nothing but the tags row is
/// under test and nothing reaches the network.
///
/// Goes through a real router because `PersonDetailScreen` reads the router
/// config to decide whether to offer its "back to people" button.
Future<void> _pumpDetail(WidgetTester tester, Person person) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final router = GoRouter(
    initialLocation: '/people/${person.id}',
    routes: [
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

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        allPeopleProvider.overrideWithBuild((ref, _) => [person]),
        personTagsProvider.overrideWithBuild(
          (ref, _) => const [_pickleball, _coworkers],
        ),
        personProvider.overrideWith((ref, id) => person),
        personRelationshipsProvider.overrideWith(
          (ref, id) => const <Relationship>[],
        ),
        personNotesProvider.overrideWith((ref, id) => const <Note>[]),
        personPicturesProvider.overrideWith(
          (ref, id) => const <PersonPicture>[],
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a tagged person shows every tag as a chip', (tester) async {
    await _pumpDetail(
      tester,
      const Person(
        id: 'aB3xQ',
        firstName: 'Ha',
        lastName: 'Pham',
        tags: [_pickleball, _coworkers],
      ),
    );

    expect(find.text('Pickleball Friends'), findsOneWidget);
    expect(find.text('Coworkers'), findsOneWidget);
    // The way in is labelled for a person who already has some.
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Add tags'), findsNothing);
  });

  testWidgets('an untagged person is invited to add some', (tester) async {
    await _pumpDetail(
      tester,
      const Person(id: 'cD4yR', firstName: 'Lan', lastName: 'Tran'),
    );

    expect(find.text('Add tags'), findsOneWidget);
    expect(find.text('Pickleball Friends'), findsNothing);
  });
}
