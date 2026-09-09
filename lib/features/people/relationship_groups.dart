import '../../data/models/converters.dart';
import '../../data/models/people_models.dart';

/// How the person detail screen splits a flat relationship list into sections.
///
/// All of this is client-side — the API returns one unordered list and the web
/// client does the grouping in `PersonDetail.vue`. Reproduced here rule for
/// rule so the two clients agree on what "immediate family" means.
class RelationshipGroups {
  const RelationshipGroups({
    required this.spouse,
    required this.children,
    required this.others,
  });

  /// The first Spouse row, if any. The server refuses a second one only by way
  /// of the conflicting-types rule, so `find`-style semantics match the web.
  final Relationship? spouse;

  /// Children, oldest first.
  final List<Relationship> children;

  /// Everything else — Parents, then Siblings, then Friends — oldest first
  /// within each type.
  final List<Relationship> others;

  bool get hasImmediateFamily => spouse != null || children.isNotEmpty;

  bool get isEmpty => spouse == null && children.isEmpty && others.isEmpty;

  static RelationshipGroups from(List<Relationship> relationships) {
    Relationship? spouse;
    for (final relationship in relationships) {
      if (relationship.type == RelationshipType.spouse) {
        spouse = relationship;
        break;
      }
    }

    final children = relationships
        .where((r) => r.type == RelationshipType.child)
        .toList()
      ..sort(_byAgeThenName);

    final others = relationships
        .where((r) =>
            r.type != RelationshipType.spouse &&
            r.type != RelationshipType.child)
        .toList()
      ..sort((a, b) {
        final order = _typeOrder(a.type).compareTo(_typeOrder(b.type));
        return order != 0 ? order : _byAgeThenName(a, b);
      });

    return RelationshipGroups(
      spouse: spouse,
      children: children,
      others: others,
    );
  }

  /// Parents, then Siblings, then Friends.
  static int _typeOrder(RelationshipType type) => switch (type) {
        RelationshipType.parent => 1,
        RelationshipType.sibling => 2,
        RelationshipType.friend => 3,
        _ => 4,
      };

  /// Oldest first, ties broken alphabetically on first + last name.
  static int _byAgeThenName(Relationship a, Relationship b) {
    final ageA = _sortAge(a);
    final ageB = _sortAge(b);
    if (ageA != ageB) return ageB.compareTo(ageA);
    return _sortName(a).compareTo(_sortName(b));
  }

  /// A missing birth date sorts as 999.
  ///
  /// The web calls this "puts them last", but the comparison is descending, so
  /// it actually floats them to the *top* of their group. Matched deliberately:
  /// the two clients showing the same family in a different order would be a
  /// worse bug than the ordering itself.
  static int _sortAge(Relationship relationship) {
    final birth = relationship.relatedPersonBirthDate;
    if (birth == null) return 999;
    final now = DateTime.now();
    var years = now.year - birth.year;
    final hadBirthday = now.month > birth.month ||
        (now.month == birth.month && now.day >= birth.day);
    if (!hadBirthday) years--;
    return years < 0 ? 999 : years;
  }

  static String _sortName(Relationship relationship) =>
      '${relationship.relatedPersonFirstName ?? ''}'
              '${relationship.relatedPersonLastName ?? ''}'
          .toLowerCase();
}
