import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';
import 'package:pham_dash_flutter/features/people/people_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// No profile pictures: an avatar with a stored path would reach for the
/// network, and these tests are about the search box.
const _people = [
  Person(id: 'a1', firstName: 'Ha', lastName: 'Pham'),
  Person(id: 'b2', firstName: 'Minh', lastName: 'Nguyen'),
  Person(id: 'c3', firstName: 'Lan', lastName: 'Tran', vietnameseName: 'Lan'),
];

Future<ProviderContainer> _pumpPeople(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      allPeopleProvider.overrideWithBuild((ref, _) => _people),
      // PeopleScreen sizes its app bar on the tag vocabulary, so it has to be
      // stubbed or the screen reaches for the network.
      personTagsProvider.overrideWithBuild((ref, _) => const <PersonTag>[]),
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
  return container;
}

Finder _clearSearchButton() =>
    find.widgetWithIcon(IconButton, Icons.close);

Finder _clearAllButton() =>
    find.widgetWithIcon(IconButton, Icons.filter_alt_off_outlined);

void main() {
  testWidgets('searching narrows the list', (tester) async {
    await _pumpPeople(tester);

    expect(find.text('Ha Pham'), findsOneWidget);
    expect(find.text('Minh Nguyen'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'minh');
    await tester.pumpAndSettle();

    expect(find.text('Minh Nguyen'), findsOneWidget);
    expect(find.text('Ha Pham'), findsNothing);
  });

  testWidgets('the clear button empties the field and restores the list',
      (tester) async {
    await _pumpPeople(tester);

    // Nothing to clear before a search has been typed.
    expect(_clearSearchButton(), findsNothing);

    await tester.enterText(find.byType(TextField), 'minh');
    await tester.pumpAndSettle();
    expect(_clearSearchButton(), findsOneWidget);

    await tester.tap(_clearSearchButton());
    await tester.pumpAndSettle();

    expect(find.text('Ha Pham'), findsOneWidget);
    expect(find.text('Minh Nguyen'), findsOneWidget);
    expect(_clearSearchButton(), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  // The bug this suite exists for: the search outlives the widget, so a field
  // that starts blank comes back empty over a still-filtered list.
  testWidgets('a rebuilt search field shows the search that is still active',
      (tester) async {
    final container = await _pumpPeople(tester);

    await tester.enterText(find.byType(TextField), 'lan');
    await tester.pumpAndSettle();
    expect(find.text('Ha Pham'), findsNothing);

    // Stand in for navigating to a person and back: the screen is rebuilt from
    // scratch against the same container.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold()),
      ),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PeopleScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'lan',
    );
    expect(_clearSearchButton(), findsOneWidget);
  });

  testWidgets('the app bar offers a clear only while something is filtered',
      (tester) async {
    await _pumpPeople(tester);

    expect(_clearAllButton(), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(_clearAllButton(), findsWidgets);

    // The app-bar action is the first of the two; the empty state's button is
    // a FilledButton, not an IconButton.
    await tester.tap(_clearAllButton().first);
    await tester.pumpAndSettle();

    expect(_clearAllButton(), findsNothing);
    expect(find.text('Ha Pham'), findsOneWidget);
  });

  testWidgets('a hygiene filter alone offers the clear, with no search typed',
      (tester) async {
    await _pumpPeople(tester);

    // Everyone in the fixture is missing a birth date, so the filter keeps all
    // three — what matters is that the escape hatch appears. The count in the
    // label is what distinguishes the switch from the rows' own "No birthday".
    await tester.tap(find.widgetWithIcon(IconButton, Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No birthday (3)'));
    await tester.pumpAndSettle();
    // Back to the screen, so the app bar action is unambiguous again.
    Navigator.of(tester.element(find.byType(PeopleScreen))).pop();
    await tester.pumpAndSettle();

    expect(_clearAllButton(), findsOneWidget);
    expect(_clearSearchButton(), findsNothing);

    await tester.tap(_clearAllButton());
    await tester.pumpAndSettle();

    expect(_clearAllButton(), findsNothing);
  });

  testWidgets('no matches offers a way out', (tester) async {
    await _pumpPeople(tester);

    await tester.enterText(find.byType(TextField), 'nobody');
    await tester.pumpAndSettle();

    expect(find.text('No matches'), findsOneWidget);

    await tester.tap(find.text('Clear search and filters'));
    await tester.pumpAndSettle();

    expect(find.text('No matches'), findsNothing);
    expect(find.text('Ha Pham'), findsOneWidget);
  });
}
