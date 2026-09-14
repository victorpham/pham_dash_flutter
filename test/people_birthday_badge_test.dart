import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';
import 'package:pham_dash_flutter/features/people/people_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _today = DateTime.now();

/// A person whose birthday falls [days] from today, aged 30 at the time.
///
/// No profile picture: an avatar with a stored path would reach for the
/// network, and these tests are about the badge drawn beside it.
Person _inDays(int days, {required String first, required String last}) {
  final target =
      DateTime(_today.year, _today.month, _today.day).add(Duration(days: days));
  return Person(
    id: '$first$last',
    firstName: first,
    lastName: last,
    birthDate: DateTime(target.year - 30, target.month, target.day),
  );
}

Future<void> _pumpPeople(WidgetTester tester, List<Person> people) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      allPeopleProvider.overrideWith((ref) => people),
      // PeopleScreen sizes its app bar on the tag vocabulary, so it has to be
      // stubbed or the screen reaches for the network.
      personTagsProvider.overrideWith((ref) => const <PersonTag>[]),
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

/// The names on screen, in the order the list draws them.
List<String> _rowsInOrder(WidgetTester tester) => tester
    .widgetList<ListTile>(find.byType(ListTile))
    .map((tile) => ((tile.title! as Row).children.first as Expanded).child)
    .map((title) => (title as Text).data!)
    .toList();

ListTile _tileFor(WidgetTester tester, String name) => tester.widget<ListTile>(
      find.ancestor(of: find.text(name), matching: find.byType(ListTile)),
    );

void main() {
  testWidgets("today's birthday leads the list, even below the alphabet",
      (tester) async {
    await _pumpPeople(tester, [
      _inDays(3, first: 'Amy', last: 'Aaronson'),
      _inDays(0, first: 'Zoe', last: 'Tran'),
      Person(id: 'none', firstName: 'Bo', lastName: 'Nguyen'),
    ]);

    expect(_rowsInOrder(tester).first, 'Zoe Tran');
  });

  testWidgets('the birthday row is badged, tinted and labelled',
      (tester) async {
    await _pumpPeople(tester, [
      _inDays(0, first: 'Zoe', last: 'Tran'),
      _inDays(3, first: 'Amy', last: 'Aaronson'),
    ]);

    // The pill says what the day is, in as many words.
    expect(find.text('Birthday today'), findsOneWidget);
    expect(find.text('In 3 days'), findsOneWidget);

    // A cake on the avatar and one in the pill.
    expect(find.byIcon(Icons.cake), findsNWidgets(2));

    // And the row itself is tinted, which the others are not.
    expect(_tileFor(tester, 'Zoe Tran').tileColor, isNotNull);
    expect(_tileFor(tester, 'Amy Aaronson').tileColor, isNull);
  });

  testWidgets('the subtitle says the age being turned', (tester) async {
    await _pumpPeople(tester, [_inDays(0, first: 'Zoe', last: 'Tran')]);

    expect(
      find.textContaining('turns 30 today'),
      findsOneWidget,
    );
  });

  testWidgets('nobody is badged when no birthday falls today', (tester) async {
    await _pumpPeople(tester, [
      _inDays(3, first: 'Amy', last: 'Aaronson'),
      Person(id: 'none', firstName: 'Bo', lastName: 'Nguyen'),
    ]);

    expect(find.byIcon(Icons.cake), findsNothing);
    expect(find.text('Birthday today'), findsNothing);
  });
}
