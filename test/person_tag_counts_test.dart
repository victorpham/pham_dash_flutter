import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/features/people/person_tag_counts.dart';

const _pickleball = PersonTag(id: 1, name: 'Pickleball Friends', personCount: 0);
const _coworkers = PersonTag(id: 2, name: 'Coworkers', personCount: 0);

/// The embedded copies always carry `personCount: 0`, which is exactly why
/// these counts are derived from the people instead.
Person _person(String id, {List<PersonTag> tags = const []}) =>
    Person(id: id, firstName: 'A', lastName: id, tags: tags);

void main() {
  test('an empty directory counts nothing', () {
    final counts = PersonTagCounts.from(const []);

    expect(counts.isEmpty, isTrue);
    expect(counts.of(_pickleball.id), 0);
  });

  test('counts each person carrying a tag', () {
    final counts = PersonTagCounts.from([
      _person('a', tags: const [_pickleball]),
      _person('b', tags: const [_pickleball]),
      _person('c'),
    ]);

    expect(counts.of(_pickleball.id), 2);
  });

  test('a person under two tags is counted under both', () {
    final counts = PersonTagCounts.from([
      _person('a', tags: const [_pickleball, _coworkers]),
    ]);

    expect(counts.of(_pickleball.id), 1);
    expect(counts.of(_coworkers.id), 1);
  });

  // The chip for an unused tag still renders, so its count has to be a number.
  test('a tag nobody carries reports zero rather than being absent', () {
    final counts = PersonTagCounts.from([
      _person('a', tags: const [_pickleball]),
    ]);

    expect(counts.of(_coworkers.id), 0);
  });

  test('nobody tagged at all leaves every count at zero', () {
    final counts = PersonTagCounts.from([_person('a'), _person('b')]);

    expect(counts.isEmpty, isTrue);
    expect(counts.of(_pickleball.id), 0);
  });
}
