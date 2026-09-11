// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'people_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Person {

/// A 5-character random alphanumeric id generated server-side, not a GUID.
 String get id; String get firstName; String get lastName; String? get vietnameseName;@WallClock() DateTime? get birthDate;/// Root-relative, e.g. `/uploads/profile-pictures/aB3xQ_20260101120000.jpg`.
/// Resolve with `AppConfig.mediaUrl`. Not updatable through `PUT` - use the
/// dedicated upload endpoint, which also deletes the previous file.
 String? get profilePictureUrl;
/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonCopyWith<Person> get copyWith => _$PersonCopyWithImpl<Person>(this as Person, _$identity);

  /// Serializes this Person to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Person;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Person&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.firstName, _this.firstName) || other.firstName == _this.firstName)&&(identical(other.lastName, _this.lastName) || other.lastName == _this.lastName)&&(identical(other.vietnameseName, _this.vietnameseName) || other.vietnameseName == _this.vietnameseName)&&(identical(other.birthDate, _this.birthDate) || other.birthDate == _this.birthDate)&&(identical(other.profilePictureUrl, _this.profilePictureUrl) || other.profilePictureUrl == _this.profilePictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Person;
  return Object.hash(runtimeType,_this.id,_this.firstName,_this.lastName,_this.vietnameseName,_this.birthDate,_this.profilePictureUrl);
}

@override
String toString() {
  final _this = this as Person;
  return 'Person(id: ${_this.id}, firstName: ${_this.firstName}, lastName: ${_this.lastName}, vietnameseName: ${_this.vietnameseName}, birthDate: ${_this.birthDate}, profilePictureUrl: ${_this.profilePictureUrl})';
}


}

/// @nodoc
abstract mixin class $PersonCopyWith<$Res>  {
  factory $PersonCopyWith(Person value, $Res Function(Person) _then) = _$PersonCopyWithImpl;
@useResult
$Res call({
 String id, String firstName, String lastName, String? vietnameseName,@WallClock() DateTime? birthDate, String? profilePictureUrl
});




}
/// @nodoc
class _$PersonCopyWithImpl<$Res>
    implements $PersonCopyWith<$Res> {
  _$PersonCopyWithImpl(this._self, this._then);

  final Person _self;
  final $Res Function(Person) _then;

/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? firstName = null,Object? lastName = null,Object? vietnameseName = freezed,Object? birthDate = freezed,Object? profilePictureUrl = freezed,}) {
  return _then(Person(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,vietnameseName: freezed == vietnameseName ? _self.vietnameseName : vietnameseName // ignore: cast_nullable_to_non_nullable
as String?,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Person].
extension PersonPatterns on Person {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Person value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Person() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Person value)  $default,){
final _that = this;
switch (_that) {
case _Person():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Person value)?  $default,){
final _that = this;
switch (_that) {
case _Person() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String firstName,  String lastName,  String? vietnameseName, @WallClock()  DateTime? birthDate,  String? profilePictureUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Person() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName,_that.vietnameseName,_that.birthDate,_that.profilePictureUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String firstName,  String lastName,  String? vietnameseName, @WallClock()  DateTime? birthDate,  String? profilePictureUrl)  $default,) {final _that = this;
switch (_that) {
case _Person():
return $default(_that.id,_that.firstName,_that.lastName,_that.vietnameseName,_that.birthDate,_that.profilePictureUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String firstName,  String lastName,  String? vietnameseName, @WallClock()  DateTime? birthDate,  String? profilePictureUrl)?  $default,) {final _that = this;
switch (_that) {
case _Person() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName,_that.vietnameseName,_that.birthDate,_that.profilePictureUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Person extends Person {
  const _Person({required this.id, required this.firstName, required this.lastName, this.vietnameseName, @WallClock() this.birthDate, this.profilePictureUrl}): super._();
  factory _Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);

/// A 5-character random alphanumeric id generated server-side, not a GUID.
@override final  String id;
@override final  String firstName;
@override final  String lastName;
@override final  String? vietnameseName;
@override@WallClock() final  DateTime? birthDate;
/// Root-relative, e.g. `/uploads/profile-pictures/aB3xQ_20260101120000.jpg`.
/// Resolve with `AppConfig.mediaUrl`. Not updatable through `PUT` - use the
/// dedicated upload endpoint, which also deletes the previous file.
@override final  String? profilePictureUrl;

/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonCopyWith<_Person> get copyWith => __$PersonCopyWithImpl<_Person>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Person&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.vietnameseName, vietnameseName) || other.vietnameseName == vietnameseName)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,firstName,lastName,vietnameseName,birthDate,profilePictureUrl);
}

@override
String toString() {
    return 'Person(id: $id, firstName: $firstName, lastName: $lastName, vietnameseName: $vietnameseName, birthDate: $birthDate, profilePictureUrl: $profilePictureUrl)';
}


}

/// @nodoc
abstract mixin class _$PersonCopyWith<$Res> implements $PersonCopyWith<$Res> {
  factory _$PersonCopyWith(_Person value, $Res Function(_Person) _then) = __$PersonCopyWithImpl;
@override @useResult
$Res call({
 String id, String firstName, String lastName, String? vietnameseName,@WallClock() DateTime? birthDate, String? profilePictureUrl
});




}
/// @nodoc
class __$PersonCopyWithImpl<$Res>
    implements _$PersonCopyWith<$Res> {
  __$PersonCopyWithImpl(this._self, this._then);

  final _Person _self;
  final $Res Function(_Person) _then;

/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? firstName = null,Object? lastName = null,Object? vietnameseName = freezed,Object? birthDate = freezed,Object? profilePictureUrl = freezed,}) {
  return _then(_Person(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,vietnameseName: freezed == vietnameseName ? _self.vietnameseName : vietnameseName // ignore: cast_nullable_to_non_nullable
as String?,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$UpcomingBirthday {

 String get id; String get firstName; String get lastName;@WallClock() DateTime? get birthDate; String? get profilePictureUrl;@JsonKey(defaultValue: 0) int get daysUntilBirthday; int? get upcomingAge;
/// Create a copy of UpcomingBirthday
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpcomingBirthdayCopyWith<UpcomingBirthday> get copyWith => _$UpcomingBirthdayCopyWithImpl<UpcomingBirthday>(this as UpcomingBirthday, _$identity);

  /// Serializes this UpcomingBirthday to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UpcomingBirthday;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpcomingBirthday&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.firstName, _this.firstName) || other.firstName == _this.firstName)&&(identical(other.lastName, _this.lastName) || other.lastName == _this.lastName)&&(identical(other.birthDate, _this.birthDate) || other.birthDate == _this.birthDate)&&(identical(other.profilePictureUrl, _this.profilePictureUrl) || other.profilePictureUrl == _this.profilePictureUrl)&&(identical(other.daysUntilBirthday, _this.daysUntilBirthday) || other.daysUntilBirthday == _this.daysUntilBirthday)&&(identical(other.upcomingAge, _this.upcomingAge) || other.upcomingAge == _this.upcomingAge));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UpcomingBirthday;
  return Object.hash(runtimeType,_this.id,_this.firstName,_this.lastName,_this.birthDate,_this.profilePictureUrl,_this.daysUntilBirthday,_this.upcomingAge);
}

@override
String toString() {
  final _this = this as UpcomingBirthday;
  return 'UpcomingBirthday(id: ${_this.id}, firstName: ${_this.firstName}, lastName: ${_this.lastName}, birthDate: ${_this.birthDate}, profilePictureUrl: ${_this.profilePictureUrl}, daysUntilBirthday: ${_this.daysUntilBirthday}, upcomingAge: ${_this.upcomingAge})';
}


}

/// @nodoc
abstract mixin class $UpcomingBirthdayCopyWith<$Res>  {
  factory $UpcomingBirthdayCopyWith(UpcomingBirthday value, $Res Function(UpcomingBirthday) _then) = _$UpcomingBirthdayCopyWithImpl;
@useResult
$Res call({
 String id, String firstName, String lastName,@WallClock() DateTime? birthDate, String? profilePictureUrl,@JsonKey(defaultValue: 0) int daysUntilBirthday, int? upcomingAge
});




}
/// @nodoc
class _$UpcomingBirthdayCopyWithImpl<$Res>
    implements $UpcomingBirthdayCopyWith<$Res> {
  _$UpcomingBirthdayCopyWithImpl(this._self, this._then);

  final UpcomingBirthday _self;
  final $Res Function(UpcomingBirthday) _then;

/// Create a copy of UpcomingBirthday
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? firstName = null,Object? lastName = null,Object? birthDate = freezed,Object? profilePictureUrl = freezed,Object? daysUntilBirthday = null,Object? upcomingAge = freezed,}) {
  return _then(UpcomingBirthday(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,daysUntilBirthday: null == daysUntilBirthday ? _self.daysUntilBirthday : daysUntilBirthday // ignore: cast_nullable_to_non_nullable
as int,upcomingAge: freezed == upcomingAge ? _self.upcomingAge : upcomingAge // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpcomingBirthday].
extension UpcomingBirthdayPatterns on UpcomingBirthday {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpcomingBirthday value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpcomingBirthday() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpcomingBirthday value)  $default,){
final _that = this;
switch (_that) {
case _UpcomingBirthday():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpcomingBirthday value)?  $default,){
final _that = this;
switch (_that) {
case _UpcomingBirthday() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String firstName,  String lastName, @WallClock()  DateTime? birthDate,  String? profilePictureUrl, @JsonKey(defaultValue: 0)  int daysUntilBirthday,  int? upcomingAge)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpcomingBirthday() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName,_that.birthDate,_that.profilePictureUrl,_that.daysUntilBirthday,_that.upcomingAge);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String firstName,  String lastName, @WallClock()  DateTime? birthDate,  String? profilePictureUrl, @JsonKey(defaultValue: 0)  int daysUntilBirthday,  int? upcomingAge)  $default,) {final _that = this;
switch (_that) {
case _UpcomingBirthday():
return $default(_that.id,_that.firstName,_that.lastName,_that.birthDate,_that.profilePictureUrl,_that.daysUntilBirthday,_that.upcomingAge);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String firstName,  String lastName, @WallClock()  DateTime? birthDate,  String? profilePictureUrl, @JsonKey(defaultValue: 0)  int daysUntilBirthday,  int? upcomingAge)?  $default,) {final _that = this;
switch (_that) {
case _UpcomingBirthday() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName,_that.birthDate,_that.profilePictureUrl,_that.daysUntilBirthday,_that.upcomingAge);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpcomingBirthday extends UpcomingBirthday {
  const _UpcomingBirthday({required this.id, required this.firstName, required this.lastName, @WallClock() this.birthDate, this.profilePictureUrl, @JsonKey(defaultValue: 0) required this.daysUntilBirthday, this.upcomingAge}): super._();
  factory _UpcomingBirthday.fromJson(Map<String, dynamic> json) => _$UpcomingBirthdayFromJson(json);

@override final  String id;
@override final  String firstName;
@override final  String lastName;
@override@WallClock() final  DateTime? birthDate;
@override final  String? profilePictureUrl;
@override@JsonKey(defaultValue: 0) final  int daysUntilBirthday;
@override final  int? upcomingAge;

/// Create a copy of UpcomingBirthday
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpcomingBirthdayCopyWith<_UpcomingBirthday> get copyWith => __$UpcomingBirthdayCopyWithImpl<_UpcomingBirthday>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpcomingBirthdayToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpcomingBirthday&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl)&&(identical(other.daysUntilBirthday, daysUntilBirthday) || other.daysUntilBirthday == daysUntilBirthday)&&(identical(other.upcomingAge, upcomingAge) || other.upcomingAge == upcomingAge));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,firstName,lastName,birthDate,profilePictureUrl,daysUntilBirthday,upcomingAge);
}

@override
String toString() {
    return 'UpcomingBirthday(id: $id, firstName: $firstName, lastName: $lastName, birthDate: $birthDate, profilePictureUrl: $profilePictureUrl, daysUntilBirthday: $daysUntilBirthday, upcomingAge: $upcomingAge)';
}


}

/// @nodoc
abstract mixin class _$UpcomingBirthdayCopyWith<$Res> implements $UpcomingBirthdayCopyWith<$Res> {
  factory _$UpcomingBirthdayCopyWith(_UpcomingBirthday value, $Res Function(_UpcomingBirthday) _then) = __$UpcomingBirthdayCopyWithImpl;
@override @useResult
$Res call({
 String id, String firstName, String lastName,@WallClock() DateTime? birthDate, String? profilePictureUrl,@JsonKey(defaultValue: 0) int daysUntilBirthday, int? upcomingAge
});




}
/// @nodoc
class __$UpcomingBirthdayCopyWithImpl<$Res>
    implements _$UpcomingBirthdayCopyWith<$Res> {
  __$UpcomingBirthdayCopyWithImpl(this._self, this._then);

  final _UpcomingBirthday _self;
  final $Res Function(_UpcomingBirthday) _then;

/// Create a copy of UpcomingBirthday
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? firstName = null,Object? lastName = null,Object? birthDate = freezed,Object? profilePictureUrl = freezed,Object? daysUntilBirthday = null,Object? upcomingAge = freezed,}) {
  return _then(_UpcomingBirthday(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,daysUntilBirthday: null == daysUntilBirthday ? _self.daysUntilBirthday : daysUntilBirthday // ignore: cast_nullable_to_non_nullable
as int,upcomingAge: freezed == upcomingAge ? _self.upcomingAge : upcomingAge // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$Note {

 int get noteId; String get personId; String get content;@UtcStamp() DateTime? get createdAt; String? get category;/// Included only by `GET /api/notes/recent`, which is what lets the recent
/// notes feed render an avatar without an extra request per note.
 Person? get person;
/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteCopyWith<Note> get copyWith => _$NoteCopyWithImpl<Note>(this as Note, _$identity);

  /// Serializes this Note to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Note;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Note&&(identical(other.noteId, _this.noteId) || other.noteId == _this.noteId)&&(identical(other.personId, _this.personId) || other.personId == _this.personId)&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.person, _this.person) || other.person == _this.person));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Note;
  return Object.hash(runtimeType,_this.noteId,_this.personId,_this.content,_this.createdAt,_this.category,_this.person);
}

@override
String toString() {
  final _this = this as Note;
  return 'Note(noteId: ${_this.noteId}, personId: ${_this.personId}, content: ${_this.content}, createdAt: ${_this.createdAt}, category: ${_this.category}, person: ${_this.person})';
}


}

/// @nodoc
abstract mixin class $NoteCopyWith<$Res>  {
  factory $NoteCopyWith(Note value, $Res Function(Note) _then) = _$NoteCopyWithImpl;
@useResult
$Res call({
 int noteId, String personId, String content,@UtcStamp() DateTime? createdAt, String? category, Person? person
});


$PersonCopyWith<$Res>? get person;

}
/// @nodoc
class _$NoteCopyWithImpl<$Res>
    implements $NoteCopyWith<$Res> {
  _$NoteCopyWithImpl(this._self, this._then);

  final Note _self;
  final $Res Function(Note) _then;

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? noteId = null,Object? personId = null,Object? content = null,Object? createdAt = freezed,Object? category = freezed,Object? person = freezed,}) {
  return _then(Note(
noteId: null == noteId ? _self.noteId : noteId // ignore: cast_nullable_to_non_nullable
as int,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,person: freezed == person ? _self.person : person // ignore: cast_nullable_to_non_nullable
as Person?,
  ));
}
/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonCopyWith<$Res>? get person {
    if (_self.person == null) {
    return null;
  }

  return $PersonCopyWith<$Res>(_self.person!, (value) {
    return _then(_self.copyWith(person: value));
  });
}
}


/// Adds pattern-matching-related methods to [Note].
extension NotePatterns on Note {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Note value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Note() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Note value)  $default,){
final _that = this;
switch (_that) {
case _Note():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Note value)?  $default,){
final _that = this;
switch (_that) {
case _Note() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int noteId,  String personId,  String content, @UtcStamp()  DateTime? createdAt,  String? category,  Person? person)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Note() when $default != null:
return $default(_that.noteId,_that.personId,_that.content,_that.createdAt,_that.category,_that.person);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int noteId,  String personId,  String content, @UtcStamp()  DateTime? createdAt,  String? category,  Person? person)  $default,) {final _that = this;
switch (_that) {
case _Note():
return $default(_that.noteId,_that.personId,_that.content,_that.createdAt,_that.category,_that.person);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int noteId,  String personId,  String content, @UtcStamp()  DateTime? createdAt,  String? category,  Person? person)?  $default,) {final _that = this;
switch (_that) {
case _Note() when $default != null:
return $default(_that.noteId,_that.personId,_that.content,_that.createdAt,_that.category,_that.person);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Note implements Note {
  const _Note({required this.noteId, required this.personId, required this.content, @UtcStamp() this.createdAt, this.category, this.person});
  factory _Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);

@override final  int noteId;
@override final  String personId;
@override final  String content;
@override@UtcStamp() final  DateTime? createdAt;
@override final  String? category;
/// Included only by `GET /api/notes/recent`, which is what lets the recent
/// notes feed render an avatar without an extra request per note.
@override final  Person? person;

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteCopyWith<_Note> get copyWith => __$NoteCopyWithImpl<_Note>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Note&&(identical(other.noteId, noteId) || other.noteId == noteId)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.category, category) || other.category == category)&&(identical(other.person, person) || other.person == person));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,noteId,personId,content,createdAt,category,person);
}

@override
String toString() {
    return 'Note(noteId: $noteId, personId: $personId, content: $content, createdAt: $createdAt, category: $category, person: $person)';
}


}

/// @nodoc
abstract mixin class _$NoteCopyWith<$Res> implements $NoteCopyWith<$Res> {
  factory _$NoteCopyWith(_Note value, $Res Function(_Note) _then) = __$NoteCopyWithImpl;
@override @useResult
$Res call({
 int noteId, String personId, String content,@UtcStamp() DateTime? createdAt, String? category, Person? person
});


@override $PersonCopyWith<$Res>? get person;

}
/// @nodoc
class __$NoteCopyWithImpl<$Res>
    implements _$NoteCopyWith<$Res> {
  __$NoteCopyWithImpl(this._self, this._then);

  final _Note _self;
  final $Res Function(_Note) _then;

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? noteId = null,Object? personId = null,Object? content = null,Object? createdAt = freezed,Object? category = freezed,Object? person = freezed,}) {
  return _then(_Note(
noteId: null == noteId ? _self.noteId : noteId // ignore: cast_nullable_to_non_nullable
as int,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,person: freezed == person ? _self.person : person // ignore: cast_nullable_to_non_nullable
as Person?,
  ));
}

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonCopyWith<$Res>? get person {
    if (_self.person == null) {
    return null;
  }

  return $PersonCopyWith<$Res>(_self.person!, (value) {
    return _then(_self.copyWith(person: value));
  });
}
}


/// @nodoc
mixin _$Relationship {

 int get relationshipId; String get personId; String get relatedPersonId;@RelationshipTypeConverter() RelationshipType get type;@UtcStamp() DateTime? get createdAt; String? get relatedPersonFirstName; String? get relatedPersonLastName;@WallClock() DateTime? get relatedPersonBirthDate; String? get relatedPersonProfilePictureUrl;
/// Create a copy of Relationship
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelationshipCopyWith<Relationship> get copyWith => _$RelationshipCopyWithImpl<Relationship>(this as Relationship, _$identity);

  /// Serializes this Relationship to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Relationship;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Relationship&&(identical(other.relationshipId, _this.relationshipId) || other.relationshipId == _this.relationshipId)&&(identical(other.personId, _this.personId) || other.personId == _this.personId)&&(identical(other.relatedPersonId, _this.relatedPersonId) || other.relatedPersonId == _this.relatedPersonId)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.relatedPersonFirstName, _this.relatedPersonFirstName) || other.relatedPersonFirstName == _this.relatedPersonFirstName)&&(identical(other.relatedPersonLastName, _this.relatedPersonLastName) || other.relatedPersonLastName == _this.relatedPersonLastName)&&(identical(other.relatedPersonBirthDate, _this.relatedPersonBirthDate) || other.relatedPersonBirthDate == _this.relatedPersonBirthDate)&&(identical(other.relatedPersonProfilePictureUrl, _this.relatedPersonProfilePictureUrl) || other.relatedPersonProfilePictureUrl == _this.relatedPersonProfilePictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Relationship;
  return Object.hash(runtimeType,_this.relationshipId,_this.personId,_this.relatedPersonId,_this.type,_this.createdAt,_this.relatedPersonFirstName,_this.relatedPersonLastName,_this.relatedPersonBirthDate,_this.relatedPersonProfilePictureUrl);
}

@override
String toString() {
  final _this = this as Relationship;
  return 'Relationship(relationshipId: ${_this.relationshipId}, personId: ${_this.personId}, relatedPersonId: ${_this.relatedPersonId}, type: ${_this.type}, createdAt: ${_this.createdAt}, relatedPersonFirstName: ${_this.relatedPersonFirstName}, relatedPersonLastName: ${_this.relatedPersonLastName}, relatedPersonBirthDate: ${_this.relatedPersonBirthDate}, relatedPersonProfilePictureUrl: ${_this.relatedPersonProfilePictureUrl})';
}


}

/// @nodoc
abstract mixin class $RelationshipCopyWith<$Res>  {
  factory $RelationshipCopyWith(Relationship value, $Res Function(Relationship) _then) = _$RelationshipCopyWithImpl;
@useResult
$Res call({
 int relationshipId, String personId, String relatedPersonId,@RelationshipTypeConverter() RelationshipType type,@UtcStamp() DateTime? createdAt, String? relatedPersonFirstName, String? relatedPersonLastName,@WallClock() DateTime? relatedPersonBirthDate, String? relatedPersonProfilePictureUrl
});




}
/// @nodoc
class _$RelationshipCopyWithImpl<$Res>
    implements $RelationshipCopyWith<$Res> {
  _$RelationshipCopyWithImpl(this._self, this._then);

  final Relationship _self;
  final $Res Function(Relationship) _then;

/// Create a copy of Relationship
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? relationshipId = null,Object? personId = null,Object? relatedPersonId = null,Object? type = null,Object? createdAt = freezed,Object? relatedPersonFirstName = freezed,Object? relatedPersonLastName = freezed,Object? relatedPersonBirthDate = freezed,Object? relatedPersonProfilePictureUrl = freezed,}) {
  return _then(Relationship(
relationshipId: null == relationshipId ? _self.relationshipId : relationshipId // ignore: cast_nullable_to_non_nullable
as int,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,relatedPersonId: null == relatedPersonId ? _self.relatedPersonId : relatedPersonId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as RelationshipType,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,relatedPersonFirstName: freezed == relatedPersonFirstName ? _self.relatedPersonFirstName : relatedPersonFirstName // ignore: cast_nullable_to_non_nullable
as String?,relatedPersonLastName: freezed == relatedPersonLastName ? _self.relatedPersonLastName : relatedPersonLastName // ignore: cast_nullable_to_non_nullable
as String?,relatedPersonBirthDate: freezed == relatedPersonBirthDate ? _self.relatedPersonBirthDate : relatedPersonBirthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,relatedPersonProfilePictureUrl: freezed == relatedPersonProfilePictureUrl ? _self.relatedPersonProfilePictureUrl : relatedPersonProfilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Relationship].
extension RelationshipPatterns on Relationship {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Relationship value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Relationship() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Relationship value)  $default,){
final _that = this;
switch (_that) {
case _Relationship():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Relationship value)?  $default,){
final _that = this;
switch (_that) {
case _Relationship() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int relationshipId,  String personId,  String relatedPersonId, @RelationshipTypeConverter()  RelationshipType type, @UtcStamp()  DateTime? createdAt,  String? relatedPersonFirstName,  String? relatedPersonLastName, @WallClock()  DateTime? relatedPersonBirthDate,  String? relatedPersonProfilePictureUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Relationship() when $default != null:
return $default(_that.relationshipId,_that.personId,_that.relatedPersonId,_that.type,_that.createdAt,_that.relatedPersonFirstName,_that.relatedPersonLastName,_that.relatedPersonBirthDate,_that.relatedPersonProfilePictureUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int relationshipId,  String personId,  String relatedPersonId, @RelationshipTypeConverter()  RelationshipType type, @UtcStamp()  DateTime? createdAt,  String? relatedPersonFirstName,  String? relatedPersonLastName, @WallClock()  DateTime? relatedPersonBirthDate,  String? relatedPersonProfilePictureUrl)  $default,) {final _that = this;
switch (_that) {
case _Relationship():
return $default(_that.relationshipId,_that.personId,_that.relatedPersonId,_that.type,_that.createdAt,_that.relatedPersonFirstName,_that.relatedPersonLastName,_that.relatedPersonBirthDate,_that.relatedPersonProfilePictureUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int relationshipId,  String personId,  String relatedPersonId, @RelationshipTypeConverter()  RelationshipType type, @UtcStamp()  DateTime? createdAt,  String? relatedPersonFirstName,  String? relatedPersonLastName, @WallClock()  DateTime? relatedPersonBirthDate,  String? relatedPersonProfilePictureUrl)?  $default,) {final _that = this;
switch (_that) {
case _Relationship() when $default != null:
return $default(_that.relationshipId,_that.personId,_that.relatedPersonId,_that.type,_that.createdAt,_that.relatedPersonFirstName,_that.relatedPersonLastName,_that.relatedPersonBirthDate,_that.relatedPersonProfilePictureUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Relationship extends Relationship {
  const _Relationship({required this.relationshipId, required this.personId, required this.relatedPersonId, @RelationshipTypeConverter() required this.type, @UtcStamp() this.createdAt, this.relatedPersonFirstName, this.relatedPersonLastName, @WallClock() this.relatedPersonBirthDate, this.relatedPersonProfilePictureUrl}): super._();
  factory _Relationship.fromJson(Map<String, dynamic> json) => _$RelationshipFromJson(json);

@override final  int relationshipId;
@override final  String personId;
@override final  String relatedPersonId;
@override@RelationshipTypeConverter() final  RelationshipType type;
@override@UtcStamp() final  DateTime? createdAt;
@override final  String? relatedPersonFirstName;
@override final  String? relatedPersonLastName;
@override@WallClock() final  DateTime? relatedPersonBirthDate;
@override final  String? relatedPersonProfilePictureUrl;

/// Create a copy of Relationship
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RelationshipCopyWith<_Relationship> get copyWith => __$RelationshipCopyWithImpl<_Relationship>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RelationshipToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Relationship&&(identical(other.relationshipId, relationshipId) || other.relationshipId == relationshipId)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.relatedPersonId, relatedPersonId) || other.relatedPersonId == relatedPersonId)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.relatedPersonFirstName, relatedPersonFirstName) || other.relatedPersonFirstName == relatedPersonFirstName)&&(identical(other.relatedPersonLastName, relatedPersonLastName) || other.relatedPersonLastName == relatedPersonLastName)&&(identical(other.relatedPersonBirthDate, relatedPersonBirthDate) || other.relatedPersonBirthDate == relatedPersonBirthDate)&&(identical(other.relatedPersonProfilePictureUrl, relatedPersonProfilePictureUrl) || other.relatedPersonProfilePictureUrl == relatedPersonProfilePictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,relationshipId,personId,relatedPersonId,type,createdAt,relatedPersonFirstName,relatedPersonLastName,relatedPersonBirthDate,relatedPersonProfilePictureUrl);
}

@override
String toString() {
    return 'Relationship(relationshipId: $relationshipId, personId: $personId, relatedPersonId: $relatedPersonId, type: $type, createdAt: $createdAt, relatedPersonFirstName: $relatedPersonFirstName, relatedPersonLastName: $relatedPersonLastName, relatedPersonBirthDate: $relatedPersonBirthDate, relatedPersonProfilePictureUrl: $relatedPersonProfilePictureUrl)';
}


}

/// @nodoc
abstract mixin class _$RelationshipCopyWith<$Res> implements $RelationshipCopyWith<$Res> {
  factory _$RelationshipCopyWith(_Relationship value, $Res Function(_Relationship) _then) = __$RelationshipCopyWithImpl;
@override @useResult
$Res call({
 int relationshipId, String personId, String relatedPersonId,@RelationshipTypeConverter() RelationshipType type,@UtcStamp() DateTime? createdAt, String? relatedPersonFirstName, String? relatedPersonLastName,@WallClock() DateTime? relatedPersonBirthDate, String? relatedPersonProfilePictureUrl
});




}
/// @nodoc
class __$RelationshipCopyWithImpl<$Res>
    implements _$RelationshipCopyWith<$Res> {
  __$RelationshipCopyWithImpl(this._self, this._then);

  final _Relationship _self;
  final $Res Function(_Relationship) _then;

/// Create a copy of Relationship
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? relationshipId = null,Object? personId = null,Object? relatedPersonId = null,Object? type = null,Object? createdAt = freezed,Object? relatedPersonFirstName = freezed,Object? relatedPersonLastName = freezed,Object? relatedPersonBirthDate = freezed,Object? relatedPersonProfilePictureUrl = freezed,}) {
  return _then(_Relationship(
relationshipId: null == relationshipId ? _self.relationshipId : relationshipId // ignore: cast_nullable_to_non_nullable
as int,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,relatedPersonId: null == relatedPersonId ? _self.relatedPersonId : relatedPersonId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as RelationshipType,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,relatedPersonFirstName: freezed == relatedPersonFirstName ? _self.relatedPersonFirstName : relatedPersonFirstName // ignore: cast_nullable_to_non_nullable
as String?,relatedPersonLastName: freezed == relatedPersonLastName ? _self.relatedPersonLastName : relatedPersonLastName // ignore: cast_nullable_to_non_nullable
as String?,relatedPersonBirthDate: freezed == relatedPersonBirthDate ? _self.relatedPersonBirthDate : relatedPersonBirthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,relatedPersonProfilePictureUrl: freezed == relatedPersonProfilePictureUrl ? _self.relatedPersonProfilePictureUrl : relatedPersonProfilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PersonPicture {

 int get id; String get personId;/// Signed and root-relative, like [Person.profilePictureUrl]. Resolve with
/// `AppConfig.mediaUrl`, which keeps the signature query intact.
 String? get profilePictureUrl; bool get isPrimary;@UtcStamp() DateTime? get uploadedAt;
/// Create a copy of PersonPicture
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonPictureCopyWith<PersonPicture> get copyWith => _$PersonPictureCopyWithImpl<PersonPicture>(this as PersonPicture, _$identity);

  /// Serializes this PersonPicture to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PersonPicture;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonPicture&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.personId, _this.personId) || other.personId == _this.personId)&&(identical(other.profilePictureUrl, _this.profilePictureUrl) || other.profilePictureUrl == _this.profilePictureUrl)&&(identical(other.isPrimary, _this.isPrimary) || other.isPrimary == _this.isPrimary)&&(identical(other.uploadedAt, _this.uploadedAt) || other.uploadedAt == _this.uploadedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PersonPicture;
  return Object.hash(runtimeType,_this.id,_this.personId,_this.profilePictureUrl,_this.isPrimary,_this.uploadedAt);
}

@override
String toString() {
  final _this = this as PersonPicture;
  return 'PersonPicture(id: ${_this.id}, personId: ${_this.personId}, profilePictureUrl: ${_this.profilePictureUrl}, isPrimary: ${_this.isPrimary}, uploadedAt: ${_this.uploadedAt})';
}


}

/// @nodoc
abstract mixin class $PersonPictureCopyWith<$Res>  {
  factory $PersonPictureCopyWith(PersonPicture value, $Res Function(PersonPicture) _then) = _$PersonPictureCopyWithImpl;
@useResult
$Res call({
 int id, String personId, String? profilePictureUrl, bool isPrimary,@UtcStamp() DateTime? uploadedAt
});




}
/// @nodoc
class _$PersonPictureCopyWithImpl<$Res>
    implements $PersonPictureCopyWith<$Res> {
  _$PersonPictureCopyWithImpl(this._self, this._then);

  final PersonPicture _self;
  final $Res Function(PersonPicture) _then;

/// Create a copy of PersonPicture
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? personId = null,Object? profilePictureUrl = freezed,Object? isPrimary = null,Object? uploadedAt = freezed,}) {
  return _then(PersonPicture(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,uploadedAt: freezed == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonPicture].
extension PersonPicturePatterns on PersonPicture {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonPicture value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonPicture() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonPicture value)  $default,){
final _that = this;
switch (_that) {
case _PersonPicture():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonPicture value)?  $default,){
final _that = this;
switch (_that) {
case _PersonPicture() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String personId,  String? profilePictureUrl,  bool isPrimary, @UtcStamp()  DateTime? uploadedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonPicture() when $default != null:
return $default(_that.id,_that.personId,_that.profilePictureUrl,_that.isPrimary,_that.uploadedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String personId,  String? profilePictureUrl,  bool isPrimary, @UtcStamp()  DateTime? uploadedAt)  $default,) {final _that = this;
switch (_that) {
case _PersonPicture():
return $default(_that.id,_that.personId,_that.profilePictureUrl,_that.isPrimary,_that.uploadedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String personId,  String? profilePictureUrl,  bool isPrimary, @UtcStamp()  DateTime? uploadedAt)?  $default,) {final _that = this;
switch (_that) {
case _PersonPicture() when $default != null:
return $default(_that.id,_that.personId,_that.profilePictureUrl,_that.isPrimary,_that.uploadedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PersonPicture implements PersonPicture {
  const _PersonPicture({required this.id, required this.personId, this.profilePictureUrl, this.isPrimary = false, @UtcStamp() this.uploadedAt});
  factory _PersonPicture.fromJson(Map<String, dynamic> json) => _$PersonPictureFromJson(json);

@override final  int id;
@override final  String personId;
/// Signed and root-relative, like [Person.profilePictureUrl]. Resolve with
/// `AppConfig.mediaUrl`, which keeps the signature query intact.
@override final  String? profilePictureUrl;
@override@JsonKey() final  bool isPrimary;
@override@UtcStamp() final  DateTime? uploadedAt;

/// Create a copy of PersonPicture
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonPictureCopyWith<_PersonPicture> get copyWith => __$PersonPictureCopyWithImpl<_PersonPicture>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonPictureToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonPicture&&(identical(other.id, id) || other.id == id)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,personId,profilePictureUrl,isPrimary,uploadedAt);
}

@override
String toString() {
    return 'PersonPicture(id: $id, personId: $personId, profilePictureUrl: $profilePictureUrl, isPrimary: $isPrimary, uploadedAt: $uploadedAt)';
}


}

/// @nodoc
abstract mixin class _$PersonPictureCopyWith<$Res> implements $PersonPictureCopyWith<$Res> {
  factory _$PersonPictureCopyWith(_PersonPicture value, $Res Function(_PersonPicture) _then) = __$PersonPictureCopyWithImpl;
@override @useResult
$Res call({
 int id, String personId, String? profilePictureUrl, bool isPrimary,@UtcStamp() DateTime? uploadedAt
});




}
/// @nodoc
class __$PersonPictureCopyWithImpl<$Res>
    implements _$PersonPictureCopyWith<$Res> {
  __$PersonPictureCopyWithImpl(this._self, this._then);

  final _PersonPicture _self;
  final $Res Function(_PersonPicture) _then;

/// Create a copy of PersonPicture
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? personId = null,Object? profilePictureUrl = freezed,Object? isPrimary = null,Object? uploadedAt = freezed,}) {
  return _then(_PersonPicture(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,personId: null == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,uploadedAt: freezed == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
