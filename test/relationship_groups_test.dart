import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/data/models/converters.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/features/people/relationship_groups.dart';

int _nextId = 1;

Relationship _relationship(
  RelationshipType type, {
  required String firstName,
  String lastName = 'Pham',
  int? age,
  String personId = 'root1',
}) {
  final now = DateTime.now();
  return Relationship(
    relationshipId: _nextId++,
    personId: personId,
    relatedPersonId: '$firstName$lastName',
    type: type,
    relatedPersonFirstName: firstName,
    relatedPersonLastName: lastName,
    // A birthday that has already passed this year, so the age is exact
    // whenever the suite runs.
    relatedPersonBirthDate:
        age == null ? null : DateTime(now.year - age, 1, 1),
  );
}

List<String> _names(List<Relationship> relationships) =>
    relationships.map((r) => r.relatedPersonFirstName!).toList();

void main() {
  group('immediate family', () {
    test('picks out the spouse', () {
      final groups = RelationshipGroups.from([
        _relationship(RelationshipType.friend, firstName: 'Kim'),
        _relationship(RelationshipType.spouse, firstName: 'Lan'),
      ]);

      expect(groups.spouse?.relatedPersonFirstName, 'Lan');
      expect(groups.hasImmediateFamily, isTrue);
    });

    test('sorts children oldest first', () {
      final groups = RelationshipGroups.from([
        _relationship(RelationshipType.child, firstName: 'Bao', age: 4),
        _relationship(RelationshipType.child, firstName: 'An', age: 11),
        _relationship(RelationshipType.child, firstName: 'Chi', age: 7),
      ]);

      expect(_names(groups.children), ['An', 'Chi', 'Bao']);
    });

    test('breaks an age tie alphabetically', () {
      final groups = RelationshipGroups.from([
        _relationship(RelationshipType.child, firstName: 'Zoe', age: 6),
        _relationship(RelationshipType.child, firstName: 'Amy', age: 6),
      ]);

      expect(_names(groups.children), ['Amy', 'Zoe']);
    });

    test('is absent when there is neither a spouse nor a child', () {
      final groups = RelationshipGroups.from([
        _relationship(RelationshipType.sibling, firstName: 'Minh'),
      ]);

      expect(groups.hasImmediateFamily, isFalse);
      expect(groups.spouse, isNull);
    });
  });

  group('other relationships', () {
    test('orders Parents, then Siblings, then Friends', () {
      final groups = RelationshipGroups.from([
        _relationship(RelationshipType.friend, firstName: 'Kim', age: 30),
        _relationship(RelationshipType.sibling, firstName: 'Minh', age: 30),
        _relationship(RelationshipType.parent, firstName: 'Ha', age: 30),
      ]);

      expect(_names(groups.others), ['Ha', 'Minh', 'Kim']);
    });

    test('sorts oldest first inside each type', () {
      final groups = RelationshipGroups.from([
        _relationship(RelationshipType.sibling, firstName: 'Younger', age: 20),
        _relationship(RelationshipType.sibling, firstName: 'Older', age: 40),
        _relationship(RelationshipType.parent, firstName: 'Dad', age: 70),
      ]);

      expect(_names(groups.others), ['Dad', 'Older', 'Younger']);
    });

    test('excludes spouse and children', () {
      final groups = RelationshipGroups.from([
        _relationship(RelationshipType.spouse, firstName: 'Lan'),
        _relationship(RelationshipType.child, firstName: 'Bao'),
        _relationship(RelationshipType.friend, firstName: 'Kim'),
      ]);

      expect(_names(groups.others), ['Kim']);
    });
  });

  // A grandparent is a Parent row owned by one of this person's parents. The
  // helper's relatedPersonId is '<first><last>', so a parent named Ha Pham owns
  // rows under personId 'HaPham'.
  group('grandparents', () {
    test('are the parents\' own parents, oldest first', () {
      final groups = RelationshipGroups.from(
        [_relationship(RelationshipType.parent, firstName: 'Ha', age: 50)],
        everyone: [
          _relationship(RelationshipType.parent,
              firstName: 'Ong', age: 78, personId: 'HaPham'),
          _relationship(RelationshipType.parent,
              firstName: 'Ba', age: 80, personId: 'HaPham'),
          // Ha's sibling is an aunt, not a grandparent.
          _relationship(RelationshipType.sibling,
              firstName: 'Di', age: 45, personId: 'HaPham'),
          // Someone else's parent row.
          _relationship(RelationshipType.parent,
              firstName: 'Stranger', age: 90, personId: 'other'),
        ],
      );

      expect(_names(groups.grandparents), ['Ba', 'Ong']);
      expect(groups.otherCount, 3);
    });

    test('sit after Parents and before Siblings in otherRows', () {
      final groups = RelationshipGroups.from(
        [
          _relationship(RelationshipType.friend, firstName: 'Kim', age: 30),
          _relationship(RelationshipType.sibling, firstName: 'Minh', age: 30),
          _relationship(RelationshipType.parent, firstName: 'Ha', age: 50),
        ],
        everyone: [
          _relationship(RelationshipType.parent,
              firstName: 'Ba', age: 80, personId: 'HaPham'),
        ],
      );

      expect(
        groups.otherRows.map((r) => r.relationship.relatedPersonFirstName),
        ['Ha', 'Ba', 'Minh', 'Kim'],
      );
      expect(
        groups.otherRows.map((r) => r.derived),
        [false, true, false, false],
      );
      // The direct list is untouched.
      expect(_names(groups.others), ['Ha', 'Minh', 'Kim']);
    });

    test('a grandparent reachable through both parents shows once', () {
      final groups = RelationshipGroups.from(
        [
          _relationship(RelationshipType.parent, firstName: 'Ha', age: 50),
          _relationship(RelationshipType.parent, firstName: 'Nam', age: 52),
        ],
        everyone: [
          _relationship(RelationshipType.parent,
              firstName: 'Ba', age: 80, personId: 'HaPham'),
          _relationship(RelationshipType.parent,
              firstName: 'Ba', age: 80, personId: 'NamPham'),
        ],
      );

      expect(_names(groups.grandparents), ['Ba']);
    });

    test('never lists the person as their own grandparent', () {
      final groups = RelationshipGroups.from(
        [_relationship(RelationshipType.parent, firstName: 'Ha', age: 50)],
        everyone: [
          Relationship(
            relationshipId: 999,
            personId: 'HaPham',
            relatedPersonId: 'root1',
            type: RelationshipType.parent,
            relatedPersonFirstName: 'Me',
          ),
        ],
      );

      expect(groups.grandparents, isEmpty);
    });

    test('are absent without the bulk table', () {
      final groups = RelationshipGroups.from([
        _relationship(RelationshipType.parent, firstName: 'Ha', age: 50),
      ]);

      expect(groups.grandparents, isEmpty);
      expect(groups.otherCount, 1);
      expect(_names(groups.others), ['Ha']);
    });
  });

  // The web's sentinel age of 999 is commented "puts them last" but is compared
  // descending, so it floats to the top instead. Matched on purpose — see
  // RelationshipGroups._sortAge.
  test('a missing birth date sorts to the top of its group', () {
    final groups = RelationshipGroups.from([
      _relationship(RelationshipType.child, firstName: 'Known', age: 9),
      _relationship(RelationshipType.child, firstName: 'Undated'),
    ]);

    expect(_names(groups.children), ['Undated', 'Known']);
  });

  test('an empty list is empty', () {
    final groups = RelationshipGroups.from([]);

    expect(groups.isEmpty, isTrue);
    expect(groups.hasImmediateFamily, isFalse);
    expect(groups.others, isEmpty);
  });
}
