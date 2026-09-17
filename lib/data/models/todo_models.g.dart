// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TodoItem _$TodoItemFromJson(Map<String, dynamic> json) => _TodoItem(
  id: (json['id'] as num).toInt(),
  todoListId: (json['todoListId'] as num).toInt(),
  groupId: (json['groupId'] as num?)?.toInt(),
  content: json['content'] as String,
  isCompleted: json['isCompleted'] as bool? ?? false,
  displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
  indentLevel: (json['indentLevel'] as num?)?.toInt() ?? 0,
  imageUrl: json['imageUrl'] as String?,
  location: json['location'] as String?,
  createdAt: const UtcStamp().fromJson(json['createdAt'] as String?),
  completedAt: const UtcStamp().fromJson(json['completedAt'] as String?),
);

Map<String, dynamic> _$TodoItemToJson(_TodoItem instance) => <String, dynamic>{
  'id': instance.id,
  'todoListId': instance.todoListId,
  'groupId': instance.groupId,
  'content': instance.content,
  'isCompleted': instance.isCompleted,
  'displayOrder': instance.displayOrder,
  'indentLevel': instance.indentLevel,
  'imageUrl': instance.imageUrl,
  'location': instance.location,
  'createdAt': const UtcStamp().toJson(instance.createdAt),
  'completedAt': const UtcStamp().toJson(instance.completedAt),
};

_TodoItemGroup _$TodoItemGroupFromJson(Map<String, dynamic> json) =>
    _TodoItemGroup(
      id: (json['id'] as num).toInt(),
      todoListId: (json['todoListId'] as num).toInt(),
      name: json['name'] as String,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TodoItemGroupToJson(_TodoItemGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'todoListId': instance.todoListId,
      'name': instance.name,
      'displayOrder': instance.displayOrder,
      'items': instance.items,
    };

_TodoLabel _$TodoLabelFromJson(Map<String, dynamic> json) => _TodoLabel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  color: json['color'] as String?,
  listCount: (json['listCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TodoLabelToJson(_TodoLabel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': instance.color,
      'listCount': instance.listCount,
    };

_LinkedEvent _$LinkedEventFromJson(Map<String, dynamic> json) => _LinkedEvent(
  eventId: json['eventId'] as String,
  eventTitle: json['eventTitle'] as String?,
  eventStart: const RequiredWallClock().fromJson(json['eventStart'] as String),
  eventEnd: const WallClock().fromJson(json['eventEnd'] as String?),
  isAllDay: json['isAllDay'] as bool? ?? false,
);

Map<String, dynamic> _$LinkedEventToJson(_LinkedEvent instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'eventTitle': instance.eventTitle,
      'eventStart': const RequiredWallClock().toJson(instance.eventStart),
      'eventEnd': const WallClock().toJson(instance.eventEnd),
      'isAllDay': instance.isAllDay,
    };

_TodoList _$TodoListFromJson(Map<String, dynamic> json) => _TodoList(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  color: json['color'] as String?,
  isPinned: json['isPinned'] as bool? ?? false,
  isArchived: json['isArchived'] as bool? ?? false,
  displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
  createdAt: const UtcStamp().fromJson(json['createdAt'] as String?),
  updatedAt: const UtcStamp().fromJson(json['updatedAt'] as String?),
  reminderDateTime: const WallClock().fromJson(
    json['reminderDateTime'] as String?,
  ),
  scheduledTime: json['scheduledTime'] as String?,
  scheduledDays: json['scheduledDays'] as String?,
  personId: json['personId'] as String?,
  personName: json['personName'] as String?,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  groups:
      (json['groups'] as List<dynamic>?)
          ?.map((e) => TodoItemGroup.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  labels:
      (json['labels'] as List<dynamic>?)
          ?.map((e) => TodoLabel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
  completedItems: (json['completedItems'] as num?)?.toInt() ?? 0,
  linkedEvent: json['linkedEvent'] == null
      ? null
      : LinkedEvent.fromJson(json['linkedEvent'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TodoListToJson(_TodoList instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'color': instance.color,
  'isPinned': instance.isPinned,
  'isArchived': instance.isArchived,
  'displayOrder': instance.displayOrder,
  'createdAt': const UtcStamp().toJson(instance.createdAt),
  'updatedAt': const UtcStamp().toJson(instance.updatedAt),
  'reminderDateTime': const WallClock().toJson(instance.reminderDateTime),
  'scheduledTime': instance.scheduledTime,
  'scheduledDays': instance.scheduledDays,
  'personId': instance.personId,
  'personName': instance.personName,
  'items': instance.items,
  'groups': instance.groups,
  'labels': instance.labels,
  'totalItems': instance.totalItems,
  'completedItems': instance.completedItems,
  'linkedEvent': instance.linkedEvent,
};

_CreateTodoList _$CreateTodoListFromJson(Map<String, dynamic> json) =>
    _CreateTodoList(
      title: json['title'] as String,
      color: json['color'] as String?,
      personId: json['personId'] as String?,
      reminderDateTime: const WallClock().fromJson(
        json['reminderDateTime'] as String?,
      ),
      scheduledTime: json['scheduledTime'] as String?,
      scheduledDays: json['scheduledDays'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => CreateTodoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreateTodoListToJson(_CreateTodoList instance) =>
    <String, dynamic>{
      'title': instance.title,
      'color': instance.color,
      'personId': instance.personId,
      'reminderDateTime': const WallClock().toJson(instance.reminderDateTime),
      'scheduledTime': instance.scheduledTime,
      'scheduledDays': instance.scheduledDays,
      'items': instance.items,
    };

_CreateTodoItem _$CreateTodoItemFromJson(Map<String, dynamic> json) =>
    _CreateTodoItem(
      content: json['content'] as String,
      indentLevel: (json['indentLevel'] as num?)?.toInt() ?? 0,
      groupId: (json['groupId'] as num?)?.toInt(),
      location: json['location'] as String?,
    );

Map<String, dynamic> _$CreateTodoItemToJson(_CreateTodoItem instance) =>
    <String, dynamic>{
      'content': instance.content,
      'indentLevel': instance.indentLevel,
      'groupId': instance.groupId,
      'location': instance.location,
    };
