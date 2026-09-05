// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'people_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Person _$PersonFromJson(Map<String, dynamic> json) => _Person(
  id: json['id'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  vietnameseName: json['vietnameseName'] as String?,
  birthDate: const WallClock().fromJson(json['birthDate'] as String?),
  profilePictureUrl: json['profilePictureUrl'] as String?,
);

Map<String, dynamic> _$PersonToJson(_Person instance) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'vietnameseName': instance.vietnameseName,
  'birthDate': const WallClock().toJson(instance.birthDate),
  'profilePictureUrl': instance.profilePictureUrl,
};

_UpcomingBirthday _$UpcomingBirthdayFromJson(Map<String, dynamic> json) =>
    _UpcomingBirthday(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      birthDate: const WallClock().fromJson(json['birthDate'] as String?),
      profilePictureUrl: json['profilePictureUrl'] as String?,
      daysUntilBirthday: (json['daysUntilBirthday'] as num?)?.toInt() ?? 0,
      upcomingAge: (json['upcomingAge'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UpcomingBirthdayToJson(_UpcomingBirthday instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'birthDate': const WallClock().toJson(instance.birthDate),
      'profilePictureUrl': instance.profilePictureUrl,
      'daysUntilBirthday': instance.daysUntilBirthday,
      'upcomingAge': instance.upcomingAge,
    };

_Note _$NoteFromJson(Map<String, dynamic> json) => _Note(
  noteId: (json['noteId'] as num).toInt(),
  personId: json['personId'] as String,
  content: json['content'] as String,
  createdAt: const UtcStamp().fromJson(json['createdAt'] as String?),
  category: json['category'] as String?,
  person: json['person'] == null
      ? null
      : Person.fromJson(json['person'] as Map<String, dynamic>),
);

Map<String, dynamic> _$NoteToJson(_Note instance) => <String, dynamic>{
  'noteId': instance.noteId,
  'personId': instance.personId,
  'content': instance.content,
  'createdAt': const UtcStamp().toJson(instance.createdAt),
  'category': instance.category,
  'person': instance.person,
};

_Relationship _$RelationshipFromJson(Map<String, dynamic> json) =>
    _Relationship(
      relationshipId: (json['relationshipId'] as num).toInt(),
      personId: json['personId'] as String,
      relatedPersonId: json['relatedPersonId'] as String,
      type: const RelationshipTypeConverter().fromJson(
        (json['type'] as num).toInt(),
      ),
      createdAt: const UtcStamp().fromJson(json['createdAt'] as String?),
      relatedPersonFirstName: json['relatedPersonFirstName'] as String?,
      relatedPersonLastName: json['relatedPersonLastName'] as String?,
      relatedPersonBirthDate: const WallClock().fromJson(
        json['relatedPersonBirthDate'] as String?,
      ),
      relatedPersonProfilePictureUrl:
          json['relatedPersonProfilePictureUrl'] as String?,
    );

Map<String, dynamic> _$RelationshipToJson(_Relationship instance) =>
    <String, dynamic>{
      'relationshipId': instance.relationshipId,
      'personId': instance.personId,
      'relatedPersonId': instance.relatedPersonId,
      'type': const RelationshipTypeConverter().toJson(instance.type),
      'createdAt': const UtcStamp().toJson(instance.createdAt),
      'relatedPersonFirstName': instance.relatedPersonFirstName,
      'relatedPersonLastName': instance.relatedPersonLastName,
      'relatedPersonBirthDate': const WallClock().toJson(
        instance.relatedPersonBirthDate,
      ),
      'relatedPersonProfilePictureUrl': instance.relatedPersonProfilePictureUrl,
    };
