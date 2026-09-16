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

const _pickleball = PersonTag(id: 1, name: 'Pickleball Friends', personCount: 0);
const _coworkers = PersonTag(id: 2, name: 'Coworkers', personCount: 0);

/// The id the server hands back. A tag ticked while creating cannot be attached
/// until this exists, which is the ordering these tests pin.
const _createdId = 'zZ9wQ';

class _RecordingPeople extends PeopleRepository {
  _RecordingPeople(super.api);

  bool created = false;

  @override
  Future<Person?> create({
    required String firstName,
    required String lastName,
    String? vietnameseName,
    String? homeAddress,
    DateTime? birthDate,
  }) async {
    created = true;
    // Deliberately tagless, as the real POST is: the nav is not loaded on what
    // CreateAsync returns, which is why the sheet must not copy tags onto it.
    return Person(
      id: _createdId,
      firstName: firstName,
      lastName: lastName,
      vietnameseName: vietnameseName,
      birthDate: birthDate,
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
  }) async =>
      Person(id: id, firstName: firstName, lastName: lastName);
}

class _RecordingTags extends PersonTagsRepository {
  _RecordingTags(super.api);

  final List<({String personId, int tagId})> attached = [];
  final List<({String personId, int tagId})> detached = [];

  @override
  Future<void> attach(String personId, int tagId) async =>
      attached.add((personId: personId, tagId: tagId));

  @override
  Future<void> detach(String personId, int tagId) async =>
      detached.add((personId: personId, tagId: tagId));
}

Future<({_RecordingPeople people, _RecordingTags tags})> _pumpSheet(
  WidgetTester tester, {
  Person? person,
}) async {
  final people = _RecordingPeople(ApiClient(AuthService()));
  final tags = _RecordingTags(ApiClient(AuthService()));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        allPeopleProvider.overrideWithBuild((ref, _) => const <Person>[]),
        personTagsProvider.overrideWithBuild(
          (ref, _) => const [_pickleball, _coworkers],
        ),
        peopleRepositoryProvider.overrideWithValue(people),
        personTagsRepositoryProvider.overrideWithValue(tags),
      ],
      child: MaterialApp(
        home: Scaffold(body: PersonEditSheet(person: person)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (people: people, tags: tags);
}

Future<void> _fillNameAndSave(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'First name'), 'Ha');
  await tester.enterText(find.widgetWithText(TextFormField, 'Last name'), 'Pham');
  // The form is taller than the 800x600 test surface, so the button has to be
  // scrolled to before it can be hit. The real sheet is full height and
  // scrollable, so this is a harness artifact rather than a layout problem.
  await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add person'));
  await tester.tap(find.widgetWithText(FilledButton, 'Add person'));
  await tester.pumpAndSettle();
}

void main() {
  // The ordering guard. A tag ticked on a *create* has no person id to attach
  // to until the POST answers, so the attach has to happen after it and with
  // the returned id - the same trap the picture upload already solved.
  testWidgets('a tag ticked while creating attaches to the new id',
      (tester) async {
    final recorded = await _pumpSheet(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Pickleball Friends'));
    await tester.pumpAndSettle();
    await _fillNameAndSave(tester);

    expect(recorded.people.created, isTrue);
    expect(recorded.tags.attached, [
      (personId: _createdId, tagId: _pickleball.id),
    ]);
  });

  testWidgets('creating without ticking anything attaches nothing',
      (tester) async {
    final recorded = await _pumpSheet(tester);

    await _fillNameAndSave(tester);

    expect(recorded.people.created, isTrue);
    expect(recorded.tags.attached, isEmpty);
    expect(recorded.tags.detached, isEmpty);
  });

  // On edit only the difference goes over the wire, so an untouched tag costs
  // no request.
  testWidgets('editing sends only what changed', (tester) async {
    final recorded = await _pumpSheet(
      tester,
      person: const Person(
        id: 'aB3xQ',
        firstName: 'Ha',
        lastName: 'Pham',
        tags: [_pickleball],
      ),
    );

    // Drop the one it has, add the one it does not. Pumped between the taps:
    // the picker takes the selection as a prop, so a second tap in the same
    // frame would compute from the pre-tap set.
    await tester.tap(find.widgetWithText(FilterChip, 'Pickleball Friends'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Coworkers'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(recorded.tags.attached, [
      (personId: 'aB3xQ', tagId: _coworkers.id),
    ]);
    expect(recorded.tags.detached, [
      (personId: 'aB3xQ', tagId: _pickleball.id),
    ]);
  });

  testWidgets('an edit that leaves the tags alone sends no tag requests',
      (tester) async {
    final recorded = await _pumpSheet(
      tester,
      person: const Person(
        id: 'aB3xQ',
        firstName: 'Ha',
        lastName: 'Pham',
        tags: [_pickleball],
      ),
    );

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(recorded.tags.attached, isEmpty);
    expect(recorded.tags.detached, isEmpty);
  });

  testWidgets('the sheet opens with existing tags already ticked',
      (tester) async {
    await _pumpSheet(
      tester,
      person: const Person(
        id: 'aB3xQ',
        firstName: 'Ha',
        lastName: 'Pham',
        tags: [_pickleball],
      ),
    );

    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Pickleball Friends'),
    );
    expect(chip.selected, isTrue);
  });
}
