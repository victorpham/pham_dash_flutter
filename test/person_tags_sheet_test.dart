import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/api/api_exception.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/data/repositories/people_repository.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';
import 'package:pham_dash_flutter/features/people/person_tags_sheet.dart';

const _pickleball = PersonTag(id: 1, name: 'Pickleball Friends', personCount: 2);
const _coworkers = PersonTag(id: 2, name: 'Coworkers', personCount: 0);

/// Carries one of the two tags, so the sheet opens with a mixed set of ticks.
const _person = Person(
  id: 'aB3xQ',
  firstName: 'Ha',
  lastName: 'Pham',
  tags: [_pickleball],
);

/// Records what the sheet sent, and can be told to fail.
///
/// Subclasses rather than implements: `PersonTagsRepository` holds a private
/// `ApiClient`, which another library cannot satisfy. Only the two methods
/// under test are overridden, so the client is never touched.
class _RecordingTags extends PersonTagsRepository {
  _RecordingTags(super.api, {this.throws = false});

  final bool throws;
  final List<({String personId, int tagId})> attached = [];
  final List<({String personId, int tagId})> detached = [];

  @override
  Future<void> attach(String personId, int tagId) async {
    attached.add((personId: personId, tagId: tagId));
    if (throws) throw const ApiException(500, 'Nope.');
  }

  @override
  Future<void> detach(String personId, int tagId) async {
    detached.add((personId: personId, tagId: tagId));
    if (throws) throw const ApiException(500, 'Nope.');
  }
}

Future<_RecordingTags> _pumpSheet(
  WidgetTester tester, {
  Person? person = _person,
  bool throws = false,
}) async {
  final tags = _RecordingTags(ApiClient(AuthService()), throws: throws);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        personTagsProvider.overrideWith((ref) => const [_pickleball, _coworkers]),
        personTagsRepositoryProvider.overrideWithValue(tags),
      ],
      child: MaterialApp(
        home: Scaffold(body: PersonTagList(person: person)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tags;
}

Finder _checkboxFor(String tagName) => find.ancestor(
      of: find.text(tagName),
      matching: find.byType(ListTile),
    );

bool _isTicked(WidgetTester tester, String tagName) {
  final checkbox = tester.widget<Checkbox>(
    find.descendant(of: _checkboxFor(tagName), matching: find.byType(Checkbox)),
  );
  return checkbox.value ?? false;
}

void main() {
  testWidgets('opens with the tags the person already carries ticked',
      (tester) async {
    await _pumpSheet(tester);

    expect(_isTicked(tester, 'Pickleball Friends'), isTrue);
    expect(_isTicked(tester, 'Coworkers'), isFalse);
  });

  testWidgets('ticking a tag attaches it once, for the right person',
      (tester) async {
    final tags = await _pumpSheet(tester);

    await tester.tap(find.text('Coworkers'));
    await tester.pumpAndSettle();

    expect(tags.attached, [(personId: 'aB3xQ', tagId: _coworkers.id)]);
    expect(tags.detached, isEmpty);
    expect(_isTicked(tester, 'Coworkers'), isTrue);
  });

  testWidgets('unticking a tag detaches it', (tester) async {
    final tags = await _pumpSheet(tester);

    await tester.tap(find.text('Pickleball Friends'));
    await tester.pumpAndSettle();

    expect(tags.detached, [(personId: 'aB3xQ', tagId: _pickleball.id)]);
    expect(_isTicked(tester, 'Pickleball Friends'), isFalse);
  });

  // The behaviour the whole optimistic toggle exists for: the tick goes on
  // immediately, so when the request fails it has to come back off.
  testWidgets('a failed attach rolls the tick back and says so',
      (tester) async {
    await _pumpSheet(tester, throws: true);

    await tester.tap(find.text('Coworkers'));
    await tester.pumpAndSettle();

    expect(_isTicked(tester, 'Coworkers'), isFalse);
    expect(find.text('Nope.'), findsOneWidget);
  });

  testWidgets('a failed detach puts the tick back on', (tester) async {
    await _pumpSheet(tester, throws: true);

    await tester.tap(find.text('Pickleball Friends'));
    await tester.pumpAndSettle();

    expect(_isTicked(tester, 'Pickleball Friends'), isTrue);
    expect(find.text('Nope.'), findsOneWidget);
  });

  // Opened from the people screen rather than a person: the same list, managing
  // the vocabulary instead of applying it.
  testWidgets('without a person there is nothing to tick', (tester) async {
    final tags = await _pumpSheet(tester, person: null);

    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('Pickleball Friends'), findsOneWidget);

    await tester.tap(find.text('Pickleball Friends'));
    await tester.pumpAndSettle();

    expect(tags.attached, isEmpty);
    expect(tags.detached, isEmpty);
  });

  testWidgets('the person count is spelled out per tag', (tester) async {
    await _pumpSheet(tester);

    expect(find.text('2 people'), findsOneWidget);
    expect(find.text('0 people'), findsOneWidget);
  });
}
