import '../../data/models/people_models.dart';

/// How many of the loaded people carry each tag.
///
/// Deliberately computed from the directory rather than read off
/// `PersonTag.personCount`: the number on a filter chip has to equal the number
/// of rows tapping it will produce, and only the list already in memory knows
/// that. It also updates for free after an attach, which already invalidates
/// the directory.
///
/// The server's `personCount` is still the right number on the manage sheet,
/// where it is a delete's blast radius and must be family-wide.
class PersonTagCounts {
  const PersonTagCounts(this._byTagId);

  final Map<int, int> _byTagId;

  /// Zero for a tag nobody carries, rather than absent — the chip still renders.
  int of(int tagId) => _byTagId[tagId] ?? 0;

  bool get isEmpty => _byTagId.isEmpty;

  static PersonTagCounts from(List<Person> people) {
    final counts = <int, int>{};
    for (final person in people) {
      for (final tag in person.tags) {
        counts[tag.id] = (counts[tag.id] ?? 0) + 1;
      }
    }
    return PersonTagCounts(counts);
  }
}
