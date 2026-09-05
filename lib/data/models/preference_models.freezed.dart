// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'preference_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserPreference {

/// Hex, e.g. `#10b981`. Used as the Material colour-scheme seed.
 String? get primaryColor;/// PrimeVue-specific; no Material equivalent, ignored on mobile.
 String? get themePreset;/// PrimeVue-specific; ignored on mobile.
 String? get surfaceColor; bool? get darkMode;
/// Create a copy of UserPreference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserPreferenceCopyWith<UserPreference> get copyWith => _$UserPreferenceCopyWithImpl<UserPreference>(this as UserPreference, _$identity);

  /// Serializes this UserPreference to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UserPreference;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPreference&&(identical(other.primaryColor, _this.primaryColor) || other.primaryColor == _this.primaryColor)&&(identical(other.themePreset, _this.themePreset) || other.themePreset == _this.themePreset)&&(identical(other.surfaceColor, _this.surfaceColor) || other.surfaceColor == _this.surfaceColor)&&(identical(other.darkMode, _this.darkMode) || other.darkMode == _this.darkMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UserPreference;
  return Object.hash(runtimeType,_this.primaryColor,_this.themePreset,_this.surfaceColor,_this.darkMode);
}

@override
String toString() {
  final _this = this as UserPreference;
  return 'UserPreference(primaryColor: ${_this.primaryColor}, themePreset: ${_this.themePreset}, surfaceColor: ${_this.surfaceColor}, darkMode: ${_this.darkMode})';
}


}

/// @nodoc
abstract mixin class $UserPreferenceCopyWith<$Res>  {
  factory $UserPreferenceCopyWith(UserPreference value, $Res Function(UserPreference) _then) = _$UserPreferenceCopyWithImpl;
@useResult
$Res call({
 String? primaryColor, String? themePreset, String? surfaceColor, bool? darkMode
});




}
/// @nodoc
class _$UserPreferenceCopyWithImpl<$Res>
    implements $UserPreferenceCopyWith<$Res> {
  _$UserPreferenceCopyWithImpl(this._self, this._then);

  final UserPreference _self;
  final $Res Function(UserPreference) _then;

/// Create a copy of UserPreference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? primaryColor = freezed,Object? themePreset = freezed,Object? surfaceColor = freezed,Object? darkMode = freezed,}) {
  return _then(UserPreference(
primaryColor: freezed == primaryColor ? _self.primaryColor : primaryColor // ignore: cast_nullable_to_non_nullable
as String?,themePreset: freezed == themePreset ? _self.themePreset : themePreset // ignore: cast_nullable_to_non_nullable
as String?,surfaceColor: freezed == surfaceColor ? _self.surfaceColor : surfaceColor // ignore: cast_nullable_to_non_nullable
as String?,darkMode: freezed == darkMode ? _self.darkMode : darkMode // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserPreference].
extension UserPreferencePatterns on UserPreference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserPreference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserPreference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserPreference value)  $default,){
final _that = this;
switch (_that) {
case _UserPreference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserPreference value)?  $default,){
final _that = this;
switch (_that) {
case _UserPreference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? primaryColor,  String? themePreset,  String? surfaceColor,  bool? darkMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserPreference() when $default != null:
return $default(_that.primaryColor,_that.themePreset,_that.surfaceColor,_that.darkMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? primaryColor,  String? themePreset,  String? surfaceColor,  bool? darkMode)  $default,) {final _that = this;
switch (_that) {
case _UserPreference():
return $default(_that.primaryColor,_that.themePreset,_that.surfaceColor,_that.darkMode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? primaryColor,  String? themePreset,  String? surfaceColor,  bool? darkMode)?  $default,) {final _that = this;
switch (_that) {
case _UserPreference() when $default != null:
return $default(_that.primaryColor,_that.themePreset,_that.surfaceColor,_that.darkMode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserPreference implements UserPreference {
  const _UserPreference({this.primaryColor, this.themePreset, this.surfaceColor, this.darkMode});
  factory _UserPreference.fromJson(Map<String, dynamic> json) => _$UserPreferenceFromJson(json);

/// Hex, e.g. `#10b981`. Used as the Material colour-scheme seed.
@override final  String? primaryColor;
/// PrimeVue-specific; no Material equivalent, ignored on mobile.
@override final  String? themePreset;
/// PrimeVue-specific; ignored on mobile.
@override final  String? surfaceColor;
@override final  bool? darkMode;

/// Create a copy of UserPreference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPreferenceCopyWith<_UserPreference> get copyWith => __$UserPreferenceCopyWithImpl<_UserPreference>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserPreferenceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPreference&&(identical(other.primaryColor, primaryColor) || other.primaryColor == primaryColor)&&(identical(other.themePreset, themePreset) || other.themePreset == themePreset)&&(identical(other.surfaceColor, surfaceColor) || other.surfaceColor == surfaceColor)&&(identical(other.darkMode, darkMode) || other.darkMode == darkMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,primaryColor,themePreset,surfaceColor,darkMode);
}

@override
String toString() {
    return 'UserPreference(primaryColor: $primaryColor, themePreset: $themePreset, surfaceColor: $surfaceColor, darkMode: $darkMode)';
}


}

/// @nodoc
abstract mixin class _$UserPreferenceCopyWith<$Res> implements $UserPreferenceCopyWith<$Res> {
  factory _$UserPreferenceCopyWith(_UserPreference value, $Res Function(_UserPreference) _then) = __$UserPreferenceCopyWithImpl;
@override @useResult
$Res call({
 String? primaryColor, String? themePreset, String? surfaceColor, bool? darkMode
});




}
/// @nodoc
class __$UserPreferenceCopyWithImpl<$Res>
    implements _$UserPreferenceCopyWith<$Res> {
  __$UserPreferenceCopyWithImpl(this._self, this._then);

  final _UserPreference _self;
  final $Res Function(_UserPreference) _then;

/// Create a copy of UserPreference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? primaryColor = freezed,Object? themePreset = freezed,Object? surfaceColor = freezed,Object? darkMode = freezed,}) {
  return _then(_UserPreference(
primaryColor: freezed == primaryColor ? _self.primaryColor : primaryColor // ignore: cast_nullable_to_non_nullable
as String?,themePreset: freezed == themePreset ? _self.themePreset : themePreset // ignore: cast_nullable_to_non_nullable
as String?,surfaceColor: freezed == surfaceColor ? _self.surfaceColor : surfaceColor // ignore: cast_nullable_to_non_nullable
as String?,darkMode: freezed == darkMode ? _self.darkMode : darkMode // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
