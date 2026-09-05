// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventCategory _$EventCategoryFromJson(Map<String, dynamic> json) =>
    _EventCategory(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      color: json['color'] as String?,
    );

Map<String, dynamic> _$EventCategoryToJson(_EventCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': instance.color,
    };

_EventAttendeeRef _$EventAttendeeRefFromJson(Map<String, dynamic> json) =>
    _EventAttendeeRef(
      personId: json['personId'] as String,
      name: json['name'] as String,
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );

Map<String, dynamic> _$EventAttendeeRefToJson(_EventAttendeeRef instance) =>
    <String, dynamic>{
      'personId': instance.personId,
      'name': instance.name,
      'profilePictureUrl': instance.profilePictureUrl,
    };

_CalendarEvent _$CalendarEventFromJson(Map<String, dynamic> json) =>
    _CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      start: const RequiredWallClock().fromJson(json['start'] as String),
      end: const RequiredWallClock().fromJson(json['end'] as String),
      isAllDay: json['isAllDay'] as bool? ?? false,
      htmlLink: json['htmlLink'] as String?,
      status: json['status'] as String?,
      attendees:
          (json['attendees'] as List<dynamic>?)
              ?.map((e) => EventAttendeeRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => EventCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$CalendarEventToJson(_CalendarEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'start': const RequiredWallClock().toJson(instance.start),
      'end': const RequiredWallClock().toJson(instance.end),
      'isAllDay': instance.isAllDay,
      'htmlLink': instance.htmlLink,
      'status': instance.status,
      'attendees': instance.attendees,
      'categories': instance.categories,
    };

_CalendarSyncStatus _$CalendarSyncStatusFromJson(Map<String, dynamic> json) =>
    _CalendarSyncStatus(
      lastSyncedAt: const UtcStamp().fromJson(json['lastSyncedAt'] as String?),
    );

Map<String, dynamic> _$CalendarSyncStatusToJson(_CalendarSyncStatus instance) =>
    <String, dynamic>{
      'lastSyncedAt': const UtcStamp().toJson(instance.lastSyncedAt),
    };

_CalendarEventAttendee _$CalendarEventAttendeeFromJson(
  Map<String, dynamic> json,
) => _CalendarEventAttendee(
  id: (json['id'] as num).toInt(),
  calendarEventId: json['calendarEventId'] as String,
  personId: json['personId'] as String,
  personName: json['personName'] as String?,
  personProfilePictureUrl: json['personProfilePictureUrl'] as String?,
  status: const AttendanceStatusConverter().fromJson(json['status'] as String?),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$CalendarEventAttendeeToJson(
  _CalendarEventAttendee instance,
) => <String, dynamic>{
  'id': instance.id,
  'calendarEventId': instance.calendarEventId,
  'personId': instance.personId,
  'personName': instance.personName,
  'personProfilePictureUrl': instance.personProfilePictureUrl,
  'status': const AttendanceStatusConverter().toJson(instance.status),
  'notes': instance.notes,
};

_AttendeeRecentNote _$AttendeeRecentNoteFromJson(Map<String, dynamic> json) =>
    _AttendeeRecentNote(
      content: json['content'] as String,
      createdAt: const UtcStamp().fromJson(json['createdAt'] as String?),
    );

Map<String, dynamic> _$AttendeeRecentNoteToJson(_AttendeeRecentNote instance) =>
    <String, dynamic>{
      'content': instance.content,
      'createdAt': const UtcStamp().toJson(instance.createdAt),
    };

_AttendeeSummary _$AttendeeSummaryFromJson(Map<String, dynamic> json) =>
    _AttendeeSummary(
      personId: json['personId'] as String,
      name: json['name'] as String,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      age: (json['age'] as num?)?.toInt(),
      recentNotes:
          (json['recentNotes'] as List<dynamic>?)
              ?.map(
                (e) => AttendeeRecentNote.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      immediateFamily:
          (json['immediateFamily'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$AttendeeSummaryToJson(_AttendeeSummary instance) =>
    <String, dynamic>{
      'personId': instance.personId,
      'name': instance.name,
      'profilePictureUrl': instance.profilePictureUrl,
      'age': instance.age,
      'recentNotes': instance.recentNotes,
      'immediateFamily': instance.immediateFamily,
    };

_EventNote _$EventNoteFromJson(Map<String, dynamic> json) => _EventNote(
  id: (json['id'] as num).toInt(),
  calendarEventId: json['calendarEventId'] as String,
  content: json['content'] as String,
  createdAt: const UtcStamp().fromJson(json['createdAt'] as String?),
  updatedAt: const UtcStamp().fromJson(json['updatedAt'] as String?),
);

Map<String, dynamic> _$EventNoteToJson(_EventNote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'calendarEventId': instance.calendarEventId,
      'content': instance.content,
      'createdAt': const UtcStamp().toJson(instance.createdAt),
      'updatedAt': const UtcStamp().toJson(instance.updatedAt),
    };

_EventTag _$EventTagFromJson(Map<String, dynamic> json) => _EventTag(
  id: (json['id'] as num).toInt(),
  calendarEventId: json['calendarEventId'] as String,
  tag: json['tag'] as String,
  color: json['color'] as String?,
);

Map<String, dynamic> _$EventTagToJson(_EventTag instance) => <String, dynamic>{
  'id': instance.id,
  'calendarEventId': instance.calendarEventId,
  'tag': instance.tag,
  'color': instance.color,
};

_LinkedTodoList _$LinkedTodoListFromJson(Map<String, dynamic> json) =>
    _LinkedTodoList(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      color: json['color'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$LinkedTodoListToJson(_LinkedTodoList instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'color': instance.color,
      'isPinned': instance.isPinned,
      'itemCount': instance.itemCount,
    };
