import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';

part 'people_models.freezed.dart';
part 'people_models.g.dart';

/// A person in the family directory.
///
/// Note that `Person` has **no `UserId` column** - people, notes and
/// relationships are shared across every authenticated user by design. "My
/// people" and "all people" are the same list.
@freezed
abstract class Person with _$Person {
  const factory Person({
    /// A 5-character random alphanumeric id generated server-side, not a GUID.
    required String id,
    required String firstName,
    required String lastName,
    String? vietnameseName,
    @WallClock() DateTime? birthDate,

    /// Root-relative, e.g. `/uploads/profile-pictures/aB3xQ_20260101120000.jpg`.
    /// Resolve with `AppConfig.mediaUrl`. Not updatable through `PUT` - use the
    /// dedicated upload endpoint, which also deletes the previous file.
    String? profilePictureUrl,
  }) = _Person;

  const Person._();

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    final combined = '$first$last'.trim();
    return combined.isEmpty ? '?' : combined.toUpperCase();
  }

  /// Age in whole years today, or null when no birth date is recorded.
  int? get age {
    final birth = birthDate;
    if (birth == null) return null;
    final now = DateTime.now();
    var years = now.year - birth.year;
    final hadBirthday = now.month > birth.month ||
        (now.month == birth.month && now.day >= birth.day);
    if (!hadBirthday) years--;
    return years < 0 ? null : years;
  }
}

/// `GET /api/people/upcoming-birthdays?count=N`.
///
/// Computed server-side across everyone with a birth date, ordered by
/// `daysUntilBirthday` ascending. Leap years are handled with `AddYears`.
@freezed
abstract class UpcomingBirthday with _$UpcomingBirthday {
  const factory UpcomingBirthday({
    required String id,
    required String firstName,
    required String lastName,
    @WallClock() DateTime? birthDate,
    String? profilePictureUrl,
    @JsonKey(defaultValue: 0) required int daysUntilBirthday,
    int? upcomingAge,
  }) = _UpcomingBirthday;

  const UpcomingBirthday._();

  factory UpcomingBirthday.fromJson(Map<String, dynamic> json) =>
      _$UpcomingBirthdayFromJson(json);

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    final combined = '$first$last'.trim();
    return combined.isEmpty ? '?' : combined.toUpperCase();
  }

  bool get isToday => daysUntilBirthday == 0;

  /// `Today!` / `Tomorrow` / `In 12 days`, matching the web widget's pill.
  String get countdownLabel => switch (daysUntilBirthday) {
        0 => 'Today!',
        1 => 'Tomorrow',
        final days => 'In $days days',
      };
}

/// A note attached to a person.
///
/// Content is authored and rendered as **Markdown** by the web client.
@freezed
abstract class Note with _$Note {
  const factory Note({
    required int noteId,
    required String personId,
    required String content,
    @UtcStamp() DateTime? createdAt,
    String? category,

    /// Included only by `GET /api/notes/recent`, which is what lets the recent
    /// notes feed render an avatar without an extra request per note.
    Person? person,
  }) = _Note;

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
}

/// `GET /api/people/{id}/relationships`.
///
/// The server fans a single create out into several rows: it always writes the
/// inverse relationship, links new siblings to all existing siblings, and gives
/// a parent's spouse the same child link. **Re-fetch after any write** rather
/// than patching local state.
@freezed
abstract class Relationship with _$Relationship {
  const factory Relationship({
    required int relationshipId,
    required String personId,
    required String relatedPersonId,
    @RelationshipTypeConverter() required RelationshipType type,
    @UtcStamp() DateTime? createdAt,
    String? relatedPersonFirstName,
    String? relatedPersonLastName,
    @WallClock() DateTime? relatedPersonBirthDate,
    String? relatedPersonProfilePictureUrl,
  }) = _Relationship;

  const Relationship._();

  factory Relationship.fromJson(Map<String, dynamic> json) =>
      _$RelationshipFromJson(json);

  String get relatedPersonName =>
      '${relatedPersonFirstName ?? ''} ${relatedPersonLastName ?? ''}'.trim();
}
