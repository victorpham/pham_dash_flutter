// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventCategory {

 int get id; String get name; String? get color;
/// Create a copy of EventCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventCategoryCopyWith<EventCategory> get copyWith => _$EventCategoryCopyWithImpl<EventCategory>(this as EventCategory, _$identity);

  /// Serializes this EventCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EventCategory;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventCategory&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.color, _this.color) || other.color == _this.color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EventCategory;
  return Object.hash(runtimeType,_this.id,_this.name,_this.color);
}

@override
String toString() {
  final _this = this as EventCategory;
  return 'EventCategory(id: ${_this.id}, name: ${_this.name}, color: ${_this.color})';
}


}

/// @nodoc
abstract mixin class $EventCategoryCopyWith<$Res>  {
  factory $EventCategoryCopyWith(EventCategory value, $Res Function(EventCategory) _then) = _$EventCategoryCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? color
});




}
/// @nodoc
class _$EventCategoryCopyWithImpl<$Res>
    implements $EventCategoryCopyWith<$Res> {
  _$EventCategoryCopyWithImpl(this._self, this._then);

  final EventCategory _self;
  final $Res Function(EventCategory) _then;

/// Create a copy of EventCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? color = freezed,}) {
  return _then(EventCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventCategory].
extension EventCategoryPatterns on EventCategory {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventCategory() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventCategory value)  $default,){
final _that = this;
switch (_that) {
case _EventCategory():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventCategory value)?  $default,){
final _that = this;
switch (_that) {
case _EventCategory() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventCategory() when $default != null:
return $default(_that.id,_that.name,_that.color);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? color)  $default,) {final _that = this;
switch (_that) {
case _EventCategory():
return $default(_that.id,_that.name,_that.color);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? color)?  $default,) {final _that = this;
switch (_that) {
case _EventCategory() when $default != null:
return $default(_that.id,_that.name,_that.color);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventCategory implements EventCategory {
  const _EventCategory({required this.id, required this.name, this.color});
  factory _EventCategory.fromJson(Map<String, dynamic> json) => _$EventCategoryFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? color;

/// Create a copy of EventCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventCategoryCopyWith<_EventCategory> get copyWith => __$EventCategoryCopyWithImpl<_EventCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,color);
}

@override
String toString() {
    return 'EventCategory(id: $id, name: $name, color: $color)';
}


}

/// @nodoc
abstract mixin class _$EventCategoryCopyWith<$Res> implements $EventCategoryCopyWith<$Res> {
  factory _$EventCategoryCopyWith(_EventCategory value, $Res Function(_EventCategory) _then) = __$EventCategoryCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? color
});




}
/// @nodoc
class __$EventCategoryCopyWithImpl<$Res>
    implements _$EventCategoryCopyWith<$Res> {
  __$EventCategoryCopyWithImpl(this._self, this._then);

  final _EventCategory _self;
  final $Res Function(_EventCategory) _then;

/// Create a copy of EventCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? color = freezed,}) {
  return _then(_EventCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$EventAttendeeRef {

 String get personId; String get name; String? get profilePictureUrl;
/// Create a copy of EventAttendeeRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventAttendeeRefCopyWith<EventAttendeeRef> get copyWith => _$EventAttendeeRefCopyWithImpl<EventAttendeeRef>(this as EventAttendeeRef, _$identity);

  /// Serializes this EventAttendeeRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EventAttendeeRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventAttendeeRef&&(identical(other.personId, _this.personId) || other.personId == _this.personId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.profilePictureUrl, _this.profilePictureUrl) || other.profilePictureUrl == _this.profilePictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EventAttendeeRef;
  return Object.hash(runtimeType,_this.personId,_this.name,_this.profilePictureUrl);
}

@override
String toString() {
  final _this = this as EventAttendeeRef;
  return 'EventAttendeeRef(personId: ${_this.personId}, name: ${_this.name}, profilePictureUrl: ${_this.profilePictureUrl})';
}


}

/// @nodoc
abstract mixin class $EventAttendeeRefCopyWith<$Res>  {
  factory $EventAttendeeRefCopyWith(EventAttendeeRef value, $Res Function(EventAttendeeRef) _then) = _$EventAttendeeRefCopyWithImpl;
@useResult
$Res call({
 String personId, String name, String? profilePictureUrl
});




}
/// @nodoc
class _$EventAttendeeRefCopyWithImpl<$Res>
    implements $EventAttendeeRefCopyWith<$Res> {
  _$EventAttendeeRefCopyWithImpl(this._self, this._then);

  final EventAttendeeRef _self;
  final $Res Function(EventAttendeeRef) _then;

/// Create a copy of EventAttendeeRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? personId = null,Object? name = null,Object? profilePictureUrl = freezed,}) {
  return _then(EventAttendeeRef(
personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventAttendeeRef].
extension EventAttendeeRefPatterns on EventAttendeeRef {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventAttendeeRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventAttendeeRef() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventAttendeeRef value)  $default,){
final _that = this;
switch (_that) {
case _EventAttendeeRef():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventAttendeeRef value)?  $default,){
final _that = this;
switch (_that) {
case _EventAttendeeRef() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String personId,  String name,  String? profilePictureUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventAttendeeRef() when $default != null:
return $default(_that.personId,_that.name,_that.profilePictureUrl);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String personId,  String name,  String? profilePictureUrl)  $default,) {final _that = this;
switch (_that) {
case _EventAttendeeRef():
return $default(_that.personId,_that.name,_that.profilePictureUrl);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String personId,  String name,  String? profilePictureUrl)?  $default,) {final _that = this;
switch (_that) {
case _EventAttendeeRef() when $default != null:
return $default(_that.personId,_that.name,_that.profilePictureUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventAttendeeRef implements EventAttendeeRef {
  const _EventAttendeeRef({required this.personId, required this.name, this.profilePictureUrl});
  factory _EventAttendeeRef.fromJson(Map<String, dynamic> json) => _$EventAttendeeRefFromJson(json);

@override final  String personId;
@override final  String name;
@override final  String? profilePictureUrl;

/// Create a copy of EventAttendeeRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventAttendeeRefCopyWith<_EventAttendeeRef> get copyWith => __$EventAttendeeRefCopyWithImpl<_EventAttendeeRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventAttendeeRefToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventAttendeeRef&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.name, name) || other.name == name)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,personId,name,profilePictureUrl);
}

@override
String toString() {
    return 'EventAttendeeRef(personId: $personId, name: $name, profilePictureUrl: $profilePictureUrl)';
}


}

/// @nodoc
abstract mixin class _$EventAttendeeRefCopyWith<$Res> implements $EventAttendeeRefCopyWith<$Res> {
  factory _$EventAttendeeRefCopyWith(_EventAttendeeRef value, $Res Function(_EventAttendeeRef) _then) = __$EventAttendeeRefCopyWithImpl;
@override @useResult
$Res call({
 String personId, String name, String? profilePictureUrl
});




}
/// @nodoc
class __$EventAttendeeRefCopyWithImpl<$Res>
    implements _$EventAttendeeRefCopyWith<$Res> {
  __$EventAttendeeRefCopyWithImpl(this._self, this._then);

  final _EventAttendeeRef _self;
  final $Res Function(_EventAttendeeRef) _then;

/// Create a copy of EventAttendeeRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? personId = null,Object? name = null,Object? profilePictureUrl = freezed,}) {
  return _then(_EventAttendeeRef(
personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CalendarEvent {

 String get id; String get title;/// May contain HTML pasted in from Google. Strip it before display.
 String? get description; String? get location;/// Wall-clock time in the calendar's own timezone - display as-is.
@RequiredWallClock() DateTime get start;@RequiredWallClock() DateTime get end;/// All-day events carry a `start` of midnight.
@JsonKey(defaultValue: false) bool get isAllDay; String? get htmlLink;/// `confirmed` | `tentative` | `cancelled`. Cancelled events are already
/// excluded server-side.
 String? get status;@JsonKey(defaultValue: <EventAttendeeRef>[]) List<EventAttendeeRef> get attendees;@JsonKey(defaultValue: <EventCategory>[]) List<EventCategory> get categories;
/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarEventCopyWith<CalendarEvent> get copyWith => _$CalendarEventCopyWithImpl<CalendarEvent>(this as CalendarEvent, _$identity);

  /// Serializes this CalendarEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CalendarEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarEvent&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.isAllDay, _this.isAllDay) || other.isAllDay == _this.isAllDay)&&(identical(other.htmlLink, _this.htmlLink) || other.htmlLink == _this.htmlLink)&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.attendees, _this.attendees)&&const DeepCollectionEquality().equals(other.categories, _this.categories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CalendarEvent;
  return Object.hash(runtimeType,_this.id,_this.title,_this.description,_this.location,_this.start,_this.end,_this.isAllDay,_this.htmlLink,_this.status,const DeepCollectionEquality().hash(_this.attendees),const DeepCollectionEquality().hash(_this.categories));
}

@override
String toString() {
  final _this = this as CalendarEvent;
  return 'CalendarEvent(id: ${_this.id}, title: ${_this.title}, description: ${_this.description}, location: ${_this.location}, start: ${_this.start}, end: ${_this.end}, isAllDay: ${_this.isAllDay}, htmlLink: ${_this.htmlLink}, status: ${_this.status}, attendees: ${_this.attendees}, categories: ${_this.categories})';
}


}

/// @nodoc
abstract mixin class $CalendarEventCopyWith<$Res>  {
  factory $CalendarEventCopyWith(CalendarEvent value, $Res Function(CalendarEvent) _then) = _$CalendarEventCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? description, String? location,@RequiredWallClock() DateTime start,@RequiredWallClock() DateTime end,@JsonKey(defaultValue: false) bool isAllDay, String? htmlLink, String? status,@JsonKey(defaultValue: <EventAttendeeRef>[]) List<EventAttendeeRef> attendees,@JsonKey(defaultValue: <EventCategory>[]) List<EventCategory> categories
});




}
/// @nodoc
class _$CalendarEventCopyWithImpl<$Res>
    implements $CalendarEventCopyWith<$Res> {
  _$CalendarEventCopyWithImpl(this._self, this._then);

  final CalendarEvent _self;
  final $Res Function(CalendarEvent) _then;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? location = freezed,Object? start = null,Object? end = null,Object? isAllDay = null,Object? htmlLink = freezed,Object? status = freezed,Object? attendees = null,Object? categories = null,}) {
  return _then(CalendarEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,isAllDay: null == isAllDay ? _self.isAllDay : isAllDay // ignore: cast_nullable_to_non_nullable
as bool,htmlLink: freezed == htmlLink ? _self.htmlLink : htmlLink // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,attendees: null == attendees ? _self.attendees : attendees // ignore: cast_nullable_to_non_nullable
as List<EventAttendeeRef>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<EventCategory>,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarEvent].
extension CalendarEventPatterns on CalendarEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarEvent value)  $default,){
final _that = this;
switch (_that) {
case _CalendarEvent():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarEvent value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  String? location, @RequiredWallClock()  DateTime start, @RequiredWallClock()  DateTime end, @JsonKey(defaultValue: false)  bool isAllDay,  String? htmlLink,  String? status, @JsonKey(defaultValue: <EventAttendeeRef>[])  List<EventAttendeeRef> attendees, @JsonKey(defaultValue: <EventCategory>[])  List<EventCategory> categories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.location,_that.start,_that.end,_that.isAllDay,_that.htmlLink,_that.status,_that.attendees,_that.categories);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  String? location, @RequiredWallClock()  DateTime start, @RequiredWallClock()  DateTime end, @JsonKey(defaultValue: false)  bool isAllDay,  String? htmlLink,  String? status, @JsonKey(defaultValue: <EventAttendeeRef>[])  List<EventAttendeeRef> attendees, @JsonKey(defaultValue: <EventCategory>[])  List<EventCategory> categories)  $default,) {final _that = this;
switch (_that) {
case _CalendarEvent():
return $default(_that.id,_that.title,_that.description,_that.location,_that.start,_that.end,_that.isAllDay,_that.htmlLink,_that.status,_that.attendees,_that.categories);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? description,  String? location, @RequiredWallClock()  DateTime start, @RequiredWallClock()  DateTime end, @JsonKey(defaultValue: false)  bool isAllDay,  String? htmlLink,  String? status, @JsonKey(defaultValue: <EventAttendeeRef>[])  List<EventAttendeeRef> attendees, @JsonKey(defaultValue: <EventCategory>[])  List<EventCategory> categories)?  $default,) {final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.location,_that.start,_that.end,_that.isAllDay,_that.htmlLink,_that.status,_that.attendees,_that.categories);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarEvent extends CalendarEvent {
  const _CalendarEvent({required this.id, required this.title, this.description, this.location, @RequiredWallClock() required this.start, @RequiredWallClock() required this.end, @JsonKey(defaultValue: false) required this.isAllDay, this.htmlLink, this.status, @JsonKey(defaultValue: <EventAttendeeRef>[]) required  List<EventAttendeeRef> attendees, @JsonKey(defaultValue: <EventCategory>[]) required  List<EventCategory> categories}): _attendees = attendees,_categories = categories,super._();
  factory _CalendarEvent.fromJson(Map<String, dynamic> json) => _$CalendarEventFromJson(json);

@override final  String id;
@override final  String title;
/// May contain HTML pasted in from Google. Strip it before display.
@override final  String? description;
@override final  String? location;
/// Wall-clock time in the calendar's own timezone - display as-is.
@override@RequiredWallClock() final  DateTime start;
@override@RequiredWallClock() final  DateTime end;
/// All-day events carry a `start` of midnight.
@override@JsonKey(defaultValue: false) final  bool isAllDay;
@override final  String? htmlLink;
/// `confirmed` | `tentative` | `cancelled`. Cancelled events are already
/// excluded server-side.
@override final  String? status;
 final  List<EventAttendeeRef> _attendees;
@override@JsonKey(defaultValue: <EventAttendeeRef>[]) List<EventAttendeeRef> get attendees {
  if (_attendees is EqualUnmodifiableListView) return _attendees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attendees);
}

 final  List<EventCategory> _categories;
@override@JsonKey(defaultValue: <EventCategory>[]) List<EventCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}


/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarEventCopyWith<_CalendarEvent> get copyWith => __$CalendarEventCopyWithImpl<_CalendarEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.location, location) || other.location == location)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.isAllDay, isAllDay) || other.isAllDay == isAllDay)&&(identical(other.htmlLink, htmlLink) || other.htmlLink == htmlLink)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.attendees, _attendees)&&const DeepCollectionEquality().equals(other.categories, _categories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,description,location,start,end,isAllDay,htmlLink,status,const DeepCollectionEquality().hash(_attendees),const DeepCollectionEquality().hash(_categories));
}

@override
String toString() {
    return 'CalendarEvent(id: $id, title: $title, description: $description, location: $location, start: $start, end: $end, isAllDay: $isAllDay, htmlLink: $htmlLink, status: $status, attendees: $attendees, categories: $categories)';
}


}

/// @nodoc
abstract mixin class _$CalendarEventCopyWith<$Res> implements $CalendarEventCopyWith<$Res> {
  factory _$CalendarEventCopyWith(_CalendarEvent value, $Res Function(_CalendarEvent) _then) = __$CalendarEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? description, String? location,@RequiredWallClock() DateTime start,@RequiredWallClock() DateTime end,@JsonKey(defaultValue: false) bool isAllDay, String? htmlLink, String? status,@JsonKey(defaultValue: <EventAttendeeRef>[]) List<EventAttendeeRef> attendees,@JsonKey(defaultValue: <EventCategory>[]) List<EventCategory> categories
});




}
/// @nodoc
class __$CalendarEventCopyWithImpl<$Res>
    implements _$CalendarEventCopyWith<$Res> {
  __$CalendarEventCopyWithImpl(this._self, this._then);

  final _CalendarEvent _self;
  final $Res Function(_CalendarEvent) _then;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? location = freezed,Object? start = null,Object? end = null,Object? isAllDay = null,Object? htmlLink = freezed,Object? status = freezed,Object? attendees = null,Object? categories = null,}) {
  return _then(_CalendarEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,isAllDay: null == isAllDay ? _self.isAllDay : isAllDay // ignore: cast_nullable_to_non_nullable
as bool,htmlLink: freezed == htmlLink ? _self.htmlLink : htmlLink // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,attendees: null == attendees ? _self._attendees : attendees // ignore: cast_nullable_to_non_nullable
as List<EventAttendeeRef>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<EventCategory>,
  ));
}


}


/// @nodoc
mixin _$CalendarSyncStatus {

/// The one timestamp in the API explicitly stamped `DateTimeKind.Utc`, so
/// it does arrive with a `Z`.
@UtcStamp() DateTime? get lastSyncedAt;
/// Create a copy of CalendarSyncStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarSyncStatusCopyWith<CalendarSyncStatus> get copyWith => _$CalendarSyncStatusCopyWithImpl<CalendarSyncStatus>(this as CalendarSyncStatus, _$identity);

  /// Serializes this CalendarSyncStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CalendarSyncStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarSyncStatus&&(identical(other.lastSyncedAt, _this.lastSyncedAt) || other.lastSyncedAt == _this.lastSyncedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CalendarSyncStatus;
  return Object.hash(runtimeType,_this.lastSyncedAt);
}

@override
String toString() {
  final _this = this as CalendarSyncStatus;
  return 'CalendarSyncStatus(lastSyncedAt: ${_this.lastSyncedAt})';
}


}

/// @nodoc
abstract mixin class $CalendarSyncStatusCopyWith<$Res>  {
  factory $CalendarSyncStatusCopyWith(CalendarSyncStatus value, $Res Function(CalendarSyncStatus) _then) = _$CalendarSyncStatusCopyWithImpl;
@useResult
$Res call({
@UtcStamp() DateTime? lastSyncedAt
});




}
/// @nodoc
class _$CalendarSyncStatusCopyWithImpl<$Res>
    implements $CalendarSyncStatusCopyWith<$Res> {
  _$CalendarSyncStatusCopyWithImpl(this._self, this._then);

  final CalendarSyncStatus _self;
  final $Res Function(CalendarSyncStatus) _then;

/// Create a copy of CalendarSyncStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lastSyncedAt = freezed,}) {
  return _then(CalendarSyncStatus(
lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarSyncStatus].
extension CalendarSyncStatusPatterns on CalendarSyncStatus {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarSyncStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarSyncStatus() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarSyncStatus value)  $default,){
final _that = this;
switch (_that) {
case _CalendarSyncStatus():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarSyncStatus value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarSyncStatus() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@UtcStamp()  DateTime? lastSyncedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarSyncStatus() when $default != null:
return $default(_that.lastSyncedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@UtcStamp()  DateTime? lastSyncedAt)  $default,) {final _that = this;
switch (_that) {
case _CalendarSyncStatus():
return $default(_that.lastSyncedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@UtcStamp()  DateTime? lastSyncedAt)?  $default,) {final _that = this;
switch (_that) {
case _CalendarSyncStatus() when $default != null:
return $default(_that.lastSyncedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarSyncStatus implements CalendarSyncStatus {
  const _CalendarSyncStatus({@UtcStamp() this.lastSyncedAt});
  factory _CalendarSyncStatus.fromJson(Map<String, dynamic> json) => _$CalendarSyncStatusFromJson(json);

/// The one timestamp in the API explicitly stamped `DateTimeKind.Utc`, so
/// it does arrive with a `Z`.
@override@UtcStamp() final  DateTime? lastSyncedAt;

/// Create a copy of CalendarSyncStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarSyncStatusCopyWith<_CalendarSyncStatus> get copyWith => __$CalendarSyncStatusCopyWithImpl<_CalendarSyncStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarSyncStatusToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarSyncStatus&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,lastSyncedAt);
}

@override
String toString() {
    return 'CalendarSyncStatus(lastSyncedAt: $lastSyncedAt)';
}


}

/// @nodoc
abstract mixin class _$CalendarSyncStatusCopyWith<$Res> implements $CalendarSyncStatusCopyWith<$Res> {
  factory _$CalendarSyncStatusCopyWith(_CalendarSyncStatus value, $Res Function(_CalendarSyncStatus) _then) = __$CalendarSyncStatusCopyWithImpl;
@override @useResult
$Res call({
@UtcStamp() DateTime? lastSyncedAt
});




}
/// @nodoc
class __$CalendarSyncStatusCopyWithImpl<$Res>
    implements _$CalendarSyncStatusCopyWith<$Res> {
  __$CalendarSyncStatusCopyWithImpl(this._self, this._then);

  final _CalendarSyncStatus _self;
  final $Res Function(_CalendarSyncStatus) _then;

/// Create a copy of CalendarSyncStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lastSyncedAt = freezed,}) {
  return _then(_CalendarSyncStatus(
lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CalendarEventAttendee {

 int get id; String get calendarEventId; String get personId; String? get personName; String? get personProfilePictureUrl;@AttendanceStatusConverter()@JsonKey(name: 'status') AttendanceStatus get status; String? get notes;
/// Create a copy of CalendarEventAttendee
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarEventAttendeeCopyWith<CalendarEventAttendee> get copyWith => _$CalendarEventAttendeeCopyWithImpl<CalendarEventAttendee>(this as CalendarEventAttendee, _$identity);

  /// Serializes this CalendarEventAttendee to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CalendarEventAttendee;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarEventAttendee&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.calendarEventId, _this.calendarEventId) || other.calendarEventId == _this.calendarEventId)&&(identical(other.personId, _this.personId) || other.personId == _this.personId)&&(identical(other.personName, _this.personName) || other.personName == _this.personName)&&(identical(other.personProfilePictureUrl, _this.personProfilePictureUrl) || other.personProfilePictureUrl == _this.personProfilePictureUrl)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.notes, _this.notes) || other.notes == _this.notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CalendarEventAttendee;
  return Object.hash(runtimeType,_this.id,_this.calendarEventId,_this.personId,_this.personName,_this.personProfilePictureUrl,_this.status,_this.notes);
}

@override
String toString() {
  final _this = this as CalendarEventAttendee;
  return 'CalendarEventAttendee(id: ${_this.id}, calendarEventId: ${_this.calendarEventId}, personId: ${_this.personId}, personName: ${_this.personName}, personProfilePictureUrl: ${_this.personProfilePictureUrl}, status: ${_this.status}, notes: ${_this.notes})';
}


}

/// @nodoc
abstract mixin class $CalendarEventAttendeeCopyWith<$Res>  {
  factory $CalendarEventAttendeeCopyWith(CalendarEventAttendee value, $Res Function(CalendarEventAttendee) _then) = _$CalendarEventAttendeeCopyWithImpl;
@useResult
$Res call({
 int id, String calendarEventId, String personId, String? personName, String? personProfilePictureUrl,@AttendanceStatusConverter()@JsonKey(name: 'status') AttendanceStatus status, String? notes
});




}
/// @nodoc
class _$CalendarEventAttendeeCopyWithImpl<$Res>
    implements $CalendarEventAttendeeCopyWith<$Res> {
  _$CalendarEventAttendeeCopyWithImpl(this._self, this._then);

  final CalendarEventAttendee _self;
  final $Res Function(CalendarEventAttendee) _then;

/// Create a copy of CalendarEventAttendee
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? calendarEventId = null,Object? personId = null,Object? personName = freezed,Object? personProfilePictureUrl = freezed,Object? status = null,Object? notes = freezed,}) {
  return _then(CalendarEventAttendee(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,calendarEventId: null == calendarEventId ? _self.calendarEventId : calendarEventId // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,personName: freezed == personName ? _self.personName : personName // ignore: cast_nullable_to_non_nullable
as String?,personProfilePictureUrl: freezed == personProfilePictureUrl ? _self.personProfilePictureUrl : personProfilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AttendanceStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarEventAttendee].
extension CalendarEventAttendeePatterns on CalendarEventAttendee {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarEventAttendee value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarEventAttendee() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarEventAttendee value)  $default,){
final _that = this;
switch (_that) {
case _CalendarEventAttendee():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarEventAttendee value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarEventAttendee() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String calendarEventId,  String personId,  String? personName,  String? personProfilePictureUrl, @AttendanceStatusConverter()@JsonKey(name: 'status')  AttendanceStatus status,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarEventAttendee() when $default != null:
return $default(_that.id,_that.calendarEventId,_that.personId,_that.personName,_that.personProfilePictureUrl,_that.status,_that.notes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String calendarEventId,  String personId,  String? personName,  String? personProfilePictureUrl, @AttendanceStatusConverter()@JsonKey(name: 'status')  AttendanceStatus status,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _CalendarEventAttendee():
return $default(_that.id,_that.calendarEventId,_that.personId,_that.personName,_that.personProfilePictureUrl,_that.status,_that.notes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String calendarEventId,  String personId,  String? personName,  String? personProfilePictureUrl, @AttendanceStatusConverter()@JsonKey(name: 'status')  AttendanceStatus status,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _CalendarEventAttendee() when $default != null:
return $default(_that.id,_that.calendarEventId,_that.personId,_that.personName,_that.personProfilePictureUrl,_that.status,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarEventAttendee implements CalendarEventAttendee {
  const _CalendarEventAttendee({required this.id, required this.calendarEventId, required this.personId, this.personName, this.personProfilePictureUrl, @AttendanceStatusConverter()@JsonKey(name: 'status') required this.status, this.notes});
  factory _CalendarEventAttendee.fromJson(Map<String, dynamic> json) => _$CalendarEventAttendeeFromJson(json);

@override final  int id;
@override final  String calendarEventId;
@override final  String personId;
@override final  String? personName;
@override final  String? personProfilePictureUrl;
@override@AttendanceStatusConverter()@JsonKey(name: 'status') final  AttendanceStatus status;
@override final  String? notes;

/// Create a copy of CalendarEventAttendee
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarEventAttendeeCopyWith<_CalendarEventAttendee> get copyWith => __$CalendarEventAttendeeCopyWithImpl<_CalendarEventAttendee>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarEventAttendeeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarEventAttendee&&(identical(other.id, id) || other.id == id)&&(identical(other.calendarEventId, calendarEventId) || other.calendarEventId == calendarEventId)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.personName, personName) || other.personName == personName)&&(identical(other.personProfilePictureUrl, personProfilePictureUrl) || other.personProfilePictureUrl == personProfilePictureUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,calendarEventId,personId,personName,personProfilePictureUrl,status,notes);
}

@override
String toString() {
    return 'CalendarEventAttendee(id: $id, calendarEventId: $calendarEventId, personId: $personId, personName: $personName, personProfilePictureUrl: $personProfilePictureUrl, status: $status, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$CalendarEventAttendeeCopyWith<$Res> implements $CalendarEventAttendeeCopyWith<$Res> {
  factory _$CalendarEventAttendeeCopyWith(_CalendarEventAttendee value, $Res Function(_CalendarEventAttendee) _then) = __$CalendarEventAttendeeCopyWithImpl;
@override @useResult
$Res call({
 int id, String calendarEventId, String personId, String? personName, String? personProfilePictureUrl,@AttendanceStatusConverter()@JsonKey(name: 'status') AttendanceStatus status, String? notes
});




}
/// @nodoc
class __$CalendarEventAttendeeCopyWithImpl<$Res>
    implements _$CalendarEventAttendeeCopyWith<$Res> {
  __$CalendarEventAttendeeCopyWithImpl(this._self, this._then);

  final _CalendarEventAttendee _self;
  final $Res Function(_CalendarEventAttendee) _then;

/// Create a copy of CalendarEventAttendee
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? calendarEventId = null,Object? personId = null,Object? personName = freezed,Object? personProfilePictureUrl = freezed,Object? status = null,Object? notes = freezed,}) {
  return _then(_CalendarEventAttendee(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,calendarEventId: null == calendarEventId ? _self.calendarEventId : calendarEventId // ignore: cast_nullable_to_non_nullable
as String,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,personName: freezed == personName ? _self.personName : personName // ignore: cast_nullable_to_non_nullable
as String?,personProfilePictureUrl: freezed == personProfilePictureUrl ? _self.personProfilePictureUrl : personProfilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AttendanceStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AttendeeRecentNote {

 String get content;@UtcStamp() DateTime? get createdAt;
/// Create a copy of AttendeeRecentNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendeeRecentNoteCopyWith<AttendeeRecentNote> get copyWith => _$AttendeeRecentNoteCopyWithImpl<AttendeeRecentNote>(this as AttendeeRecentNote, _$identity);

  /// Serializes this AttendeeRecentNote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AttendeeRecentNote;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendeeRecentNote&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AttendeeRecentNote;
  return Object.hash(runtimeType,_this.content,_this.createdAt);
}

@override
String toString() {
  final _this = this as AttendeeRecentNote;
  return 'AttendeeRecentNote(content: ${_this.content}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $AttendeeRecentNoteCopyWith<$Res>  {
  factory $AttendeeRecentNoteCopyWith(AttendeeRecentNote value, $Res Function(AttendeeRecentNote) _then) = _$AttendeeRecentNoteCopyWithImpl;
@useResult
$Res call({
 String content,@UtcStamp() DateTime? createdAt
});




}
/// @nodoc
class _$AttendeeRecentNoteCopyWithImpl<$Res>
    implements $AttendeeRecentNoteCopyWith<$Res> {
  _$AttendeeRecentNoteCopyWithImpl(this._self, this._then);

  final AttendeeRecentNote _self;
  final $Res Function(AttendeeRecentNote) _then;

/// Create a copy of AttendeeRecentNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? createdAt = freezed,}) {
  return _then(AttendeeRecentNote(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendeeRecentNote].
extension AttendeeRecentNotePatterns on AttendeeRecentNote {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendeeRecentNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendeeRecentNote() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendeeRecentNote value)  $default,){
final _that = this;
switch (_that) {
case _AttendeeRecentNote():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendeeRecentNote value)?  $default,){
final _that = this;
switch (_that) {
case _AttendeeRecentNote() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String content, @UtcStamp()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendeeRecentNote() when $default != null:
return $default(_that.content,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String content, @UtcStamp()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _AttendeeRecentNote():
return $default(_that.content,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String content, @UtcStamp()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AttendeeRecentNote() when $default != null:
return $default(_that.content,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttendeeRecentNote implements AttendeeRecentNote {
  const _AttendeeRecentNote({required this.content, @UtcStamp() this.createdAt});
  factory _AttendeeRecentNote.fromJson(Map<String, dynamic> json) => _$AttendeeRecentNoteFromJson(json);

@override final  String content;
@override@UtcStamp() final  DateTime? createdAt;

/// Create a copy of AttendeeRecentNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendeeRecentNoteCopyWith<_AttendeeRecentNote> get copyWith => __$AttendeeRecentNoteCopyWithImpl<_AttendeeRecentNote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttendeeRecentNoteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendeeRecentNote&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,content,createdAt);
}

@override
String toString() {
    return 'AttendeeRecentNote(content: $content, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AttendeeRecentNoteCopyWith<$Res> implements $AttendeeRecentNoteCopyWith<$Res> {
  factory _$AttendeeRecentNoteCopyWith(_AttendeeRecentNote value, $Res Function(_AttendeeRecentNote) _then) = __$AttendeeRecentNoteCopyWithImpl;
@override @useResult
$Res call({
 String content,@UtcStamp() DateTime? createdAt
});




}
/// @nodoc
class __$AttendeeRecentNoteCopyWithImpl<$Res>
    implements _$AttendeeRecentNoteCopyWith<$Res> {
  __$AttendeeRecentNoteCopyWithImpl(this._self, this._then);

  final _AttendeeRecentNote _self;
  final $Res Function(_AttendeeRecentNote) _then;

/// Create a copy of AttendeeRecentNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? createdAt = freezed,}) {
  return _then(_AttendeeRecentNote(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$AttendeeSummary {

 String get personId; String get name; String? get profilePictureUrl; int? get age;@JsonKey(defaultValue: <AttendeeRecentNote>[]) List<AttendeeRecentNote> get recentNotes;/// Pre-formatted `"Name (Type)"` strings, spouse/sibling/parent/child only
/// - friends are excluded server-side.
@JsonKey(defaultValue: <String>[]) List<String> get immediateFamily;
/// Create a copy of AttendeeSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendeeSummaryCopyWith<AttendeeSummary> get copyWith => _$AttendeeSummaryCopyWithImpl<AttendeeSummary>(this as AttendeeSummary, _$identity);

  /// Serializes this AttendeeSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AttendeeSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendeeSummary&&(identical(other.personId, _this.personId) || other.personId == _this.personId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.profilePictureUrl, _this.profilePictureUrl) || other.profilePictureUrl == _this.profilePictureUrl)&&(identical(other.age, _this.age) || other.age == _this.age)&&const DeepCollectionEquality().equals(other.recentNotes, _this.recentNotes)&&const DeepCollectionEquality().equals(other.immediateFamily, _this.immediateFamily));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AttendeeSummary;
  return Object.hash(runtimeType,_this.personId,_this.name,_this.profilePictureUrl,_this.age,const DeepCollectionEquality().hash(_this.recentNotes),const DeepCollectionEquality().hash(_this.immediateFamily));
}

@override
String toString() {
  final _this = this as AttendeeSummary;
  return 'AttendeeSummary(personId: ${_this.personId}, name: ${_this.name}, profilePictureUrl: ${_this.profilePictureUrl}, age: ${_this.age}, recentNotes: ${_this.recentNotes}, immediateFamily: ${_this.immediateFamily})';
}


}

/// @nodoc
abstract mixin class $AttendeeSummaryCopyWith<$Res>  {
  factory $AttendeeSummaryCopyWith(AttendeeSummary value, $Res Function(AttendeeSummary) _then) = _$AttendeeSummaryCopyWithImpl;
@useResult
$Res call({
 String personId, String name, String? profilePictureUrl, int? age,@JsonKey(defaultValue: <AttendeeRecentNote>[]) List<AttendeeRecentNote> recentNotes,@JsonKey(defaultValue: <String>[]) List<String> immediateFamily
});




}
/// @nodoc
class _$AttendeeSummaryCopyWithImpl<$Res>
    implements $AttendeeSummaryCopyWith<$Res> {
  _$AttendeeSummaryCopyWithImpl(this._self, this._then);

  final AttendeeSummary _self;
  final $Res Function(AttendeeSummary) _then;

/// Create a copy of AttendeeSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? personId = null,Object? name = null,Object? profilePictureUrl = freezed,Object? age = freezed,Object? recentNotes = null,Object? immediateFamily = null,}) {
  return _then(AttendeeSummary(
personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,recentNotes: null == recentNotes ? _self.recentNotes : recentNotes // ignore: cast_nullable_to_non_nullable
as List<AttendeeRecentNote>,immediateFamily: null == immediateFamily ? _self.immediateFamily : immediateFamily // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendeeSummary].
extension AttendeeSummaryPatterns on AttendeeSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendeeSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendeeSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendeeSummary value)  $default,){
final _that = this;
switch (_that) {
case _AttendeeSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendeeSummary value)?  $default,){
final _that = this;
switch (_that) {
case _AttendeeSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String personId,  String name,  String? profilePictureUrl,  int? age, @JsonKey(defaultValue: <AttendeeRecentNote>[])  List<AttendeeRecentNote> recentNotes, @JsonKey(defaultValue: <String>[])  List<String> immediateFamily)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendeeSummary() when $default != null:
return $default(_that.personId,_that.name,_that.profilePictureUrl,_that.age,_that.recentNotes,_that.immediateFamily);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String personId,  String name,  String? profilePictureUrl,  int? age, @JsonKey(defaultValue: <AttendeeRecentNote>[])  List<AttendeeRecentNote> recentNotes, @JsonKey(defaultValue: <String>[])  List<String> immediateFamily)  $default,) {final _that = this;
switch (_that) {
case _AttendeeSummary():
return $default(_that.personId,_that.name,_that.profilePictureUrl,_that.age,_that.recentNotes,_that.immediateFamily);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String personId,  String name,  String? profilePictureUrl,  int? age, @JsonKey(defaultValue: <AttendeeRecentNote>[])  List<AttendeeRecentNote> recentNotes, @JsonKey(defaultValue: <String>[])  List<String> immediateFamily)?  $default,) {final _that = this;
switch (_that) {
case _AttendeeSummary() when $default != null:
return $default(_that.personId,_that.name,_that.profilePictureUrl,_that.age,_that.recentNotes,_that.immediateFamily);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttendeeSummary implements AttendeeSummary {
  const _AttendeeSummary({required this.personId, required this.name, this.profilePictureUrl, this.age, @JsonKey(defaultValue: <AttendeeRecentNote>[]) required  List<AttendeeRecentNote> recentNotes, @JsonKey(defaultValue: <String>[]) required  List<String> immediateFamily}): _recentNotes = recentNotes,_immediateFamily = immediateFamily;
  factory _AttendeeSummary.fromJson(Map<String, dynamic> json) => _$AttendeeSummaryFromJson(json);

@override final  String personId;
@override final  String name;
@override final  String? profilePictureUrl;
@override final  int? age;
 final  List<AttendeeRecentNote> _recentNotes;
@override@JsonKey(defaultValue: <AttendeeRecentNote>[]) List<AttendeeRecentNote> get recentNotes {
  if (_recentNotes is EqualUnmodifiableListView) return _recentNotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentNotes);
}

/// Pre-formatted `"Name (Type)"` strings, spouse/sibling/parent/child only
/// - friends are excluded server-side.
 final  List<String> _immediateFamily;
/// Pre-formatted `"Name (Type)"` strings, spouse/sibling/parent/child only
/// - friends are excluded server-side.
@override@JsonKey(defaultValue: <String>[]) List<String> get immediateFamily {
  if (_immediateFamily is EqualUnmodifiableListView) return _immediateFamily;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_immediateFamily);
}


/// Create a copy of AttendeeSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendeeSummaryCopyWith<_AttendeeSummary> get copyWith => __$AttendeeSummaryCopyWithImpl<_AttendeeSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttendeeSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendeeSummary&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.name, name) || other.name == name)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl)&&(identical(other.age, age) || other.age == age)&&const DeepCollectionEquality().equals(other.recentNotes, _recentNotes)&&const DeepCollectionEquality().equals(other.immediateFamily, _immediateFamily));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,personId,name,profilePictureUrl,age,const DeepCollectionEquality().hash(_recentNotes),const DeepCollectionEquality().hash(_immediateFamily));
}

@override
String toString() {
    return 'AttendeeSummary(personId: $personId, name: $name, profilePictureUrl: $profilePictureUrl, age: $age, recentNotes: $recentNotes, immediateFamily: $immediateFamily)';
}


}

/// @nodoc
abstract mixin class _$AttendeeSummaryCopyWith<$Res> implements $AttendeeSummaryCopyWith<$Res> {
  factory _$AttendeeSummaryCopyWith(_AttendeeSummary value, $Res Function(_AttendeeSummary) _then) = __$AttendeeSummaryCopyWithImpl;
@override @useResult
$Res call({
 String personId, String name, String? profilePictureUrl, int? age,@JsonKey(defaultValue: <AttendeeRecentNote>[]) List<AttendeeRecentNote> recentNotes,@JsonKey(defaultValue: <String>[]) List<String> immediateFamily
});




}
/// @nodoc
class __$AttendeeSummaryCopyWithImpl<$Res>
    implements _$AttendeeSummaryCopyWith<$Res> {
  __$AttendeeSummaryCopyWithImpl(this._self, this._then);

  final _AttendeeSummary _self;
  final $Res Function(_AttendeeSummary) _then;

/// Create a copy of AttendeeSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? personId = null,Object? name = null,Object? profilePictureUrl = freezed,Object? age = freezed,Object? recentNotes = null,Object? immediateFamily = null,}) {
  return _then(_AttendeeSummary(
personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,recentNotes: null == recentNotes ? _self._recentNotes : recentNotes // ignore: cast_nullable_to_non_nullable
as List<AttendeeRecentNote>,immediateFamily: null == immediateFamily ? _self._immediateFamily : immediateFamily // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$EventNote {

 int get id; String get calendarEventId; String get content;@UtcStamp() DateTime? get createdAt;@UtcStamp() DateTime? get updatedAt;
/// Create a copy of EventNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventNoteCopyWith<EventNote> get copyWith => _$EventNoteCopyWithImpl<EventNote>(this as EventNote, _$identity);

  /// Serializes this EventNote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EventNote;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventNote&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.calendarEventId, _this.calendarEventId) || other.calendarEventId == _this.calendarEventId)&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EventNote;
  return Object.hash(runtimeType,_this.id,_this.calendarEventId,_this.content,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as EventNote;
  return 'EventNote(id: ${_this.id}, calendarEventId: ${_this.calendarEventId}, content: ${_this.content}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $EventNoteCopyWith<$Res>  {
  factory $EventNoteCopyWith(EventNote value, $Res Function(EventNote) _then) = _$EventNoteCopyWithImpl;
@useResult
$Res call({
 int id, String calendarEventId, String content,@UtcStamp() DateTime? createdAt,@UtcStamp() DateTime? updatedAt
});




}
/// @nodoc
class _$EventNoteCopyWithImpl<$Res>
    implements $EventNoteCopyWith<$Res> {
  _$EventNoteCopyWithImpl(this._self, this._then);

  final EventNote _self;
  final $Res Function(EventNote) _then;

/// Create a copy of EventNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? calendarEventId = null,Object? content = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(EventNote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,calendarEventId: null == calendarEventId ? _self.calendarEventId : calendarEventId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventNote].
extension EventNotePatterns on EventNote {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventNote() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventNote value)  $default,){
final _that = this;
switch (_that) {
case _EventNote():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventNote value)?  $default,){
final _that = this;
switch (_that) {
case _EventNote() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String calendarEventId,  String content, @UtcStamp()  DateTime? createdAt, @UtcStamp()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventNote() when $default != null:
return $default(_that.id,_that.calendarEventId,_that.content,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String calendarEventId,  String content, @UtcStamp()  DateTime? createdAt, @UtcStamp()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _EventNote():
return $default(_that.id,_that.calendarEventId,_that.content,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String calendarEventId,  String content, @UtcStamp()  DateTime? createdAt, @UtcStamp()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _EventNote() when $default != null:
return $default(_that.id,_that.calendarEventId,_that.content,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventNote implements EventNote {
  const _EventNote({required this.id, required this.calendarEventId, required this.content, @UtcStamp() this.createdAt, @UtcStamp() this.updatedAt});
  factory _EventNote.fromJson(Map<String, dynamic> json) => _$EventNoteFromJson(json);

@override final  int id;
@override final  String calendarEventId;
@override final  String content;
@override@UtcStamp() final  DateTime? createdAt;
@override@UtcStamp() final  DateTime? updatedAt;

/// Create a copy of EventNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventNoteCopyWith<_EventNote> get copyWith => __$EventNoteCopyWithImpl<_EventNote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventNoteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventNote&&(identical(other.id, id) || other.id == id)&&(identical(other.calendarEventId, calendarEventId) || other.calendarEventId == calendarEventId)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,calendarEventId,content,createdAt,updatedAt);
}

@override
String toString() {
    return 'EventNote(id: $id, calendarEventId: $calendarEventId, content: $content, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$EventNoteCopyWith<$Res> implements $EventNoteCopyWith<$Res> {
  factory _$EventNoteCopyWith(_EventNote value, $Res Function(_EventNote) _then) = __$EventNoteCopyWithImpl;
@override @useResult
$Res call({
 int id, String calendarEventId, String content,@UtcStamp() DateTime? createdAt,@UtcStamp() DateTime? updatedAt
});




}
/// @nodoc
class __$EventNoteCopyWithImpl<$Res>
    implements _$EventNoteCopyWith<$Res> {
  __$EventNoteCopyWithImpl(this._self, this._then);

  final _EventNote _self;
  final $Res Function(_EventNote) _then;

/// Create a copy of EventNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? calendarEventId = null,Object? content = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_EventNote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,calendarEventId: null == calendarEventId ? _self.calendarEventId : calendarEventId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$EventTag {

 int get id; String get calendarEventId; String get tag; String? get color;
/// Create a copy of EventTag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventTagCopyWith<EventTag> get copyWith => _$EventTagCopyWithImpl<EventTag>(this as EventTag, _$identity);

  /// Serializes this EventTag to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EventTag;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventTag&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.calendarEventId, _this.calendarEventId) || other.calendarEventId == _this.calendarEventId)&&(identical(other.tag, _this.tag) || other.tag == _this.tag)&&(identical(other.color, _this.color) || other.color == _this.color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EventTag;
  return Object.hash(runtimeType,_this.id,_this.calendarEventId,_this.tag,_this.color);
}

@override
String toString() {
  final _this = this as EventTag;
  return 'EventTag(id: ${_this.id}, calendarEventId: ${_this.calendarEventId}, tag: ${_this.tag}, color: ${_this.color})';
}


}

/// @nodoc
abstract mixin class $EventTagCopyWith<$Res>  {
  factory $EventTagCopyWith(EventTag value, $Res Function(EventTag) _then) = _$EventTagCopyWithImpl;
@useResult
$Res call({
 int id, String calendarEventId, String tag, String? color
});




}
/// @nodoc
class _$EventTagCopyWithImpl<$Res>
    implements $EventTagCopyWith<$Res> {
  _$EventTagCopyWithImpl(this._self, this._then);

  final EventTag _self;
  final $Res Function(EventTag) _then;

/// Create a copy of EventTag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? calendarEventId = null,Object? tag = null,Object? color = freezed,}) {
  return _then(EventTag(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,calendarEventId: null == calendarEventId ? _self.calendarEventId : calendarEventId // ignore: cast_nullable_to_non_nullable
as String,tag: null == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventTag].
extension EventTagPatterns on EventTag {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventTag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventTag() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventTag value)  $default,){
final _that = this;
switch (_that) {
case _EventTag():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventTag value)?  $default,){
final _that = this;
switch (_that) {
case _EventTag() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String calendarEventId,  String tag,  String? color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventTag() when $default != null:
return $default(_that.id,_that.calendarEventId,_that.tag,_that.color);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String calendarEventId,  String tag,  String? color)  $default,) {final _that = this;
switch (_that) {
case _EventTag():
return $default(_that.id,_that.calendarEventId,_that.tag,_that.color);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String calendarEventId,  String tag,  String? color)?  $default,) {final _that = this;
switch (_that) {
case _EventTag() when $default != null:
return $default(_that.id,_that.calendarEventId,_that.tag,_that.color);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventTag implements EventTag {
  const _EventTag({required this.id, required this.calendarEventId, required this.tag, this.color});
  factory _EventTag.fromJson(Map<String, dynamic> json) => _$EventTagFromJson(json);

@override final  int id;
@override final  String calendarEventId;
@override final  String tag;
@override final  String? color;

/// Create a copy of EventTag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventTagCopyWith<_EventTag> get copyWith => __$EventTagCopyWithImpl<_EventTag>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventTagToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventTag&&(identical(other.id, id) || other.id == id)&&(identical(other.calendarEventId, calendarEventId) || other.calendarEventId == calendarEventId)&&(identical(other.tag, tag) || other.tag == tag)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,calendarEventId,tag,color);
}

@override
String toString() {
    return 'EventTag(id: $id, calendarEventId: $calendarEventId, tag: $tag, color: $color)';
}


}

/// @nodoc
abstract mixin class _$EventTagCopyWith<$Res> implements $EventTagCopyWith<$Res> {
  factory _$EventTagCopyWith(_EventTag value, $Res Function(_EventTag) _then) = __$EventTagCopyWithImpl;
@override @useResult
$Res call({
 int id, String calendarEventId, String tag, String? color
});




}
/// @nodoc
class __$EventTagCopyWithImpl<$Res>
    implements _$EventTagCopyWith<$Res> {
  __$EventTagCopyWithImpl(this._self, this._then);

  final _EventTag _self;
  final $Res Function(_EventTag) _then;

/// Create a copy of EventTag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? calendarEventId = null,Object? tag = null,Object? color = freezed,}) {
  return _then(_EventTag(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,calendarEventId: null == calendarEventId ? _self.calendarEventId : calendarEventId // ignore: cast_nullable_to_non_nullable
as String,tag: null == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$LinkedTodoList {

 int get id; String get title; String? get color;@JsonKey(defaultValue: false) bool get isPinned;@JsonKey(defaultValue: 0) int get itemCount;
/// Create a copy of LinkedTodoList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkedTodoListCopyWith<LinkedTodoList> get copyWith => _$LinkedTodoListCopyWithImpl<LinkedTodoList>(this as LinkedTodoList, _$identity);

  /// Serializes this LinkedTodoList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LinkedTodoList;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkedTodoList&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.isPinned, _this.isPinned) || other.isPinned == _this.isPinned)&&(identical(other.itemCount, _this.itemCount) || other.itemCount == _this.itemCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LinkedTodoList;
  return Object.hash(runtimeType,_this.id,_this.title,_this.color,_this.isPinned,_this.itemCount);
}

@override
String toString() {
  final _this = this as LinkedTodoList;
  return 'LinkedTodoList(id: ${_this.id}, title: ${_this.title}, color: ${_this.color}, isPinned: ${_this.isPinned}, itemCount: ${_this.itemCount})';
}


}

/// @nodoc
abstract mixin class $LinkedTodoListCopyWith<$Res>  {
  factory $LinkedTodoListCopyWith(LinkedTodoList value, $Res Function(LinkedTodoList) _then) = _$LinkedTodoListCopyWithImpl;
@useResult
$Res call({
 int id, String title, String? color,@JsonKey(defaultValue: false) bool isPinned,@JsonKey(defaultValue: 0) int itemCount
});




}
/// @nodoc
class _$LinkedTodoListCopyWithImpl<$Res>
    implements $LinkedTodoListCopyWith<$Res> {
  _$LinkedTodoListCopyWithImpl(this._self, this._then);

  final LinkedTodoList _self;
  final $Res Function(LinkedTodoList) _then;

/// Create a copy of LinkedTodoList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? color = freezed,Object? isPinned = null,Object? itemCount = null,}) {
  return _then(LinkedTodoList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LinkedTodoList].
extension LinkedTodoListPatterns on LinkedTodoList {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinkedTodoList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinkedTodoList() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinkedTodoList value)  $default,){
final _that = this;
switch (_that) {
case _LinkedTodoList():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinkedTodoList value)?  $default,){
final _that = this;
switch (_that) {
case _LinkedTodoList() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String? color, @JsonKey(defaultValue: false)  bool isPinned, @JsonKey(defaultValue: 0)  int itemCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinkedTodoList() when $default != null:
return $default(_that.id,_that.title,_that.color,_that.isPinned,_that.itemCount);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String? color, @JsonKey(defaultValue: false)  bool isPinned, @JsonKey(defaultValue: 0)  int itemCount)  $default,) {final _that = this;
switch (_that) {
case _LinkedTodoList():
return $default(_that.id,_that.title,_that.color,_that.isPinned,_that.itemCount);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String? color, @JsonKey(defaultValue: false)  bool isPinned, @JsonKey(defaultValue: 0)  int itemCount)?  $default,) {final _that = this;
switch (_that) {
case _LinkedTodoList() when $default != null:
return $default(_that.id,_that.title,_that.color,_that.isPinned,_that.itemCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LinkedTodoList implements LinkedTodoList {
  const _LinkedTodoList({required this.id, required this.title, this.color, @JsonKey(defaultValue: false) required this.isPinned, @JsonKey(defaultValue: 0) required this.itemCount});
  factory _LinkedTodoList.fromJson(Map<String, dynamic> json) => _$LinkedTodoListFromJson(json);

@override final  int id;
@override final  String title;
@override final  String? color;
@override@JsonKey(defaultValue: false) final  bool isPinned;
@override@JsonKey(defaultValue: 0) final  int itemCount;

/// Create a copy of LinkedTodoList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinkedTodoListCopyWith<_LinkedTodoList> get copyWith => __$LinkedTodoListCopyWithImpl<_LinkedTodoList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LinkedTodoListToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinkedTodoList&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.color, color) || other.color == color)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,color,isPinned,itemCount);
}

@override
String toString() {
    return 'LinkedTodoList(id: $id, title: $title, color: $color, isPinned: $isPinned, itemCount: $itemCount)';
}


}

/// @nodoc
abstract mixin class _$LinkedTodoListCopyWith<$Res> implements $LinkedTodoListCopyWith<$Res> {
  factory _$LinkedTodoListCopyWith(_LinkedTodoList value, $Res Function(_LinkedTodoList) _then) = __$LinkedTodoListCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String? color,@JsonKey(defaultValue: false) bool isPinned,@JsonKey(defaultValue: 0) int itemCount
});




}
/// @nodoc
class __$LinkedTodoListCopyWithImpl<$Res>
    implements _$LinkedTodoListCopyWith<$Res> {
  __$LinkedTodoListCopyWithImpl(this._self, this._then);

  final _LinkedTodoList _self;
  final $Res Function(_LinkedTodoList) _then;

/// Create a copy of LinkedTodoList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? color = freezed,Object? isPinned = null,Object? itemCount = null,}) {
  return _then(_LinkedTodoList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
