import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../../core/api/api_date.dart';

/// A timestamp that means a **literal clock reading**, not an instant.
///
/// Applies to `calendarEvent.start` / `end`, `person.birthDate` and
/// `todoList.reminderDateTime`. See [ApiDate] for why the two kinds must not be
/// parsed the same way.
class WallClock implements JsonConverter<DateTime?, String?> {
  const WallClock();

  @override
  DateTime? fromJson(String? json) => ApiDate.wallClock(json);

  @override
  String? toJson(DateTime? object) =>
      object == null ? null : ApiDate.formatWallClock(object);
}

/// A non-nullable [WallClock], for fields the API always populates.
class RequiredWallClock implements JsonConverter<DateTime, String> {
  const RequiredWallClock();

  @override
  DateTime fromJson(String json) =>
      ApiDate.wallClock(json) ?? DateTime.fromMillisecondsSinceEpoch(0);

  @override
  String toJson(DateTime object) => ApiDate.formatWallClock(object);
}

/// A timestamp that means a **UTC instant**, usually missing its `Z`.
///
/// Applies to `createdAt`, `updatedAt`, `completedAt` and `lastSyncedAt`.
/// Decoded into local time for display.
class UtcStamp implements JsonConverter<DateTime?, String?> {
  const UtcStamp();

  @override
  DateTime? fromJson(String? json) => ApiDate.utcStamp(json);

  @override
  String? toJson(DateTime? object) => object?.toUtc().toIso8601String();
}

class RequiredUtcStamp implements JsonConverter<DateTime, String> {
  const RequiredUtcStamp();

  @override
  DateTime fromJson(String json) =>
      ApiDate.utcStamp(json) ?? DateTime.fromMillisecondsSinceEpoch(0);

  @override
  String toJson(DateTime object) => object.toUtc().toIso8601String();
}

/// `spellingWord.hiddenIndices` is a JSON array **encoded as a string**
/// (`"[1,3]"`), not a JSON array field. Any JSON decoder hands you a `String`;
/// this unpacks it into the `List<int>` it actually represents.
class HiddenIndices implements JsonConverter<List<int>, String?> {
  const HiddenIndices();

  @override
  List<int> fromJson(String? json) {
    if (json == null || json.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return const [];
      return decoded.whereType<num>().map((n) => n.toInt()).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  String toJson(List<int> object) => jsonEncode(object);
}

/// How confident we are that a person is attending an event.
///
/// This is the **one** enum the API sends as a string; every other enum on the
/// wire is an integer. `CalendarEventMetadataController` maps it by hand and
/// parses it back case-insensitively.
enum AttendanceStatus {
  unknown('Unknown'),
  confirmed('Confirmed'),
  tentative('Tentative'),
  declined('Declined');

  const AttendanceStatus(this.wireValue);

  final String wireValue;

  static AttendanceStatus parse(String? value) {
    if (value == null) return AttendanceStatus.unknown;
    final lower = value.toLowerCase();
    for (final status in AttendanceStatus.values) {
      if (status.wireValue.toLowerCase() == lower) return status;
    }
    return AttendanceStatus.unknown;
  }
}

class AttendanceStatusConverter
    implements JsonConverter<AttendanceStatus, String?> {
  const AttendanceStatusConverter();

  @override
  AttendanceStatus fromJson(String? json) => AttendanceStatus.parse(json);

  @override
  String toJson(AttendanceStatus object) => object.wireValue;
}

/// Serialized as an **integer**, unlike [AttendanceStatus].
enum RelationshipType {
  spouse(0),
  sibling(1),
  parent(2),
  child(3),
  friend(4);

  const RelationshipType(this.wireValue);

  final int wireValue;

  static RelationshipType parse(int? value) => switch (value) {
        0 => RelationshipType.spouse,
        1 => RelationshipType.sibling,
        2 => RelationshipType.parent,
        3 => RelationshipType.child,
        _ => RelationshipType.friend,
      };

  String get label => switch (this) {
        RelationshipType.spouse => 'Spouse',
        RelationshipType.sibling => 'Sibling',
        RelationshipType.parent => 'Parent',
        RelationshipType.child => 'Child',
        RelationshipType.friend => 'Friend',
      };
}

class RelationshipTypeConverter implements JsonConverter<RelationshipType, int> {
  const RelationshipTypeConverter();

  @override
  RelationshipType fromJson(int json) => RelationshipType.parse(json);

  @override
  int toJson(RelationshipType object) => object.wireValue;
}
