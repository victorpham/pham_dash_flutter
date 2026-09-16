import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/data/repositories/people_repository.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';
import 'package:pham_dash_flutter/features/people/person_edit_sheet.dart';

const _address = '123 Main St, Austin, TX 78701';

const _ha = Person(
  id: 'aB3xQ',
  firstName: 'Ha',
  lastName: 'Pham',
  homeAddress: _address,
);

/// Records the address the sheet sent.
///
/// Subclasses rather than implements: `PeopleRepository` holds a private
/// `ApiClient`, which another library cannot satisfy. Only the two writes are
/// overridden and nothing else is called, so the client is never touched.
class _RecordingPeople extends PeopleRepository {
  _RecordingPeople(super.api);

  bool saved = false;
  String? sentHomeAddress;

  @override
  Future<Person?> create({
    required String firstName,
    required String lastName,
    String? vietnameseName,
    String? homeAddress,
    DateTime? birthDate,
  }) async {
    saved = true;
    sentHomeAddress = homeAddress;
    return Person(
      id: 'new01',
      firstName: firstName,
      lastName: lastName,
      homeAddress: homeAddress,
    );
  }

  @override
  Future<Person?> update(
    String id, {
    required String firstName,
    required String lastName,
    String? vietnameseName,
    String? homeAddress,
    DateTime? birthDate,
  }) async {
    saved = true;
    sentHomeAddress = homeAddress;
    return Person(
      id: id,
      firstName: firstName,
      lastName: lastName,
      homeAddress: homeAddress,
    );
  }
}

Future<_RecordingPeople> _pumpSheet(
  WidgetTester tester, {
  Person? person,
}) async {
  final people = _RecordingPeople(ApiClient(AuthService()));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        allPeopleProvider.overrideWithBuild((ref, _) => const <Person>[]),
        personTagsProvider.overrideWithBuild((ref, _) => const <PersonTag>[]),
        peopleRepositoryProvider.overrideWithValue(people),
      ],
      child: MaterialApp(
        home: Scaffold(body: PersonEditSheet(person: person)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return people;
}

Finder _addressField() =>
    find.widgetWithText(TextFormField, 'Home address (optional)');

/// The form is taller than the 800x600 test surface, so the button has to be
/// scrolled to. The real sheet is full height and scrolls, so this is a harness
/// artifact rather than a layout problem.
Future<void> _save(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.widgetWithText(FilledButton, label));
  await tester.tap(find.widgetWithText(FilledButton, label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the sheet opens with the stored address in the field',
      (tester) async {
    await _pumpSheet(tester, person: _ha);

    expect(find.widgetWithText(TextFormField, _address), findsOneWidget);
  });

  testWidgets('a typed address reaches the repository', (tester) async {
    final people = await _pumpSheet(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'First name'),
      'Ha',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Last name'),
      'Pham',
    );
    await tester.enterText(_addressField(), _address);
    await _save(tester, 'Add person');

    expect(people.saved, isTrue);
    expect(people.sentHomeAddress, _address);
  });

  testWidgets('surrounding whitespace is trimmed off', (tester) async {
    final people = await _pumpSheet(tester, person: _ha);

    await tester.enterText(_addressField(), '   $_address   ');
    await _save(tester, 'Save');

    expect(people.sentHomeAddress, _address);
  });

  // Blank has to become null, not "". The detail screen renders the address row
  // on presence, so an empty string would leave it drawing an empty line with a
  // copy button and a map button hanging off it.
  testWidgets('clearing the field sends null rather than an empty string',
      (tester) async {
    final people = await _pumpSheet(tester, person: _ha);

    await tester.enterText(_addressField(), '');
    await _save(tester, 'Save');

    expect(people.saved, isTrue);
    expect(people.sentHomeAddress, isNull);
  });
}
