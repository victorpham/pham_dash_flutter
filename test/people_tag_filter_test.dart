import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';
import 'package:pham_dash_flutter/features/people/people_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pickleball = PersonTag(id: 1, name: 'Pickleball Friends', personCount: 2);
const _coworkers = PersonTag(id: 2, name: 'Coworkers', personCount: 0);

/// No profile pictures: an avatar with a stored path would reach for the
/// network, and these tests are about the filter bar.
const _people = [
  Person(id: 'a1', firstName: 'Ha', lastName: 'Pham', tags: [_pickleball]),
  Person(id: 'b2', firstName: 'Minh', lastName: 'Nguyen', tags: [_pickleball]),
  Person(id: 'c3', firstName: 'Lan', lastName: 'Tran'),
];

Future<void> _pumpPeople(
  WidgetTester tester, {
  List<PersonTag> tags = const [_pickleball, _coworkers],
  List<Person> people = _people,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      allPeopleProvider.overrideWith((ref) => people),
      personTagsProvider.overrideWith((ref) => tags),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: PeopleScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _clearAllButton() =>
    find.widgetWithIcon(IconButton, Icons.filter_alt_off_outlined);

void main() {
  testWidgets('tapping a tag narrows the directory to its members',
      (tester) async {
    await _pumpPeople(tester);

    expect(find.text('Lan Tran'), findsOneWidget);

    await tester.tap(find.text('Pickleball Friends (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Ha Pham'), findsOneWidget);
    expect(find.text('Minh Nguyen'), findsOneWidget);
    expect(find.text('Lan Tran'), findsNothing);
  });

  // Derived from the loaded directory, not read off PersonTag.personCount - the
  // number has to equal the rows tapping it produces.
  testWidgets('chip counts come from the people actually loaded',
      (tester) async {
    await _pumpPeople(tester);

    expect(find.text('Pickleball Friends (2)'), findsOneWidget);
    expect(find.text('Coworkers (0)'), findsOneWidget);
  });

  testWidgets('a tag and the search box narrow together', (tester) async {
    await _pumpPeople(tester);

    await tester.tap(find.text('Pickleball Friends (2)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'minh');
    await tester.pumpAndSettle();

    expect(find.text('Minh Nguyen'), findsOneWidget);
    expect(find.text('Ha Pham'), findsNothing);
  });

  // The completeness guard: a new filter has to be taught _isFilteredProvider,
  // _clearAll and filteredPeopleProvider. Missing _clearAll is the silent one -
  // the button appears and does nothing for the tag.
  testWidgets('clear search and filters drops the tag filter too',
      (tester) async {
    await _pumpPeople(tester);

    expect(_clearAllButton(), findsNothing);

    await tester.tap(find.text('Pickleball Friends (2)'));
    await tester.pumpAndSettle();
    expect(_clearAllButton(), findsOneWidget);

    await tester.tap(_clearAllButton());
    await tester.pumpAndSettle();

    expect(find.text('Lan Tran'), findsOneWidget);
    expect(_clearAllButton(), findsNothing);
  });

  testWidgets('the All chip returns the whole directory', (tester) async {
    await _pumpPeople(tester);

    await tester.tap(find.text('Pickleball Friends (2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('Lan Tran'), findsOneWidget);
  });

  testWidgets('a tag matching nobody lands on the no-matches escape hatch',
      (tester) async {
    await _pumpPeople(tester);

    await tester.tap(find.text('Coworkers (0)'));
    await tester.pumpAndSettle();

    expect(find.text('No matches'), findsOneWidget);
    expect(find.text('Clear search and filters'), findsOneWidget);
  });

  // The app bar reserves 104px without tags and 150px with them. If that ever
  // disagrees with what the bar actually builds, the result is a RenderFlex
  // overflow - yellow stripes in debug, a silent clip in release - so it is
  // asserted rather than left to be noticed.
  testWidgets('the filters fit the app bar on a narrow phone', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;

    await _pumpPeople(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('the filters fit the app bar on a tablet', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;

    await _pumpPeople(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('no tag row at all when the vocabulary is empty', (tester) async {
    await _pumpPeople(tester, tags: const []);

    expect(find.text('All'), findsNothing);
    expect(find.text('Manage'), findsNothing);
    // The two data-hygiene chips are untouched. Matched by their counted
    // labels, since "No birthday" alone is also each undated person's subtitle.
    expect(find.text('No birthday (3)'), findsOneWidget);
    expect(find.text('No photo (3)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
