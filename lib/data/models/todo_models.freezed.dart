// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TodoItem {

 int get id; int get todoListId;/// Null for an ungrouped item. Note that **sending** `groupId: 0` is what
/// removes an item from its group - see `UpdateTodoItem`.
 int? get groupId; String get content;@JsonKey(defaultValue: false) bool get isCompleted;@JsonKey(defaultValue: 0) int get displayOrder;/// 0-2. The web UI caps nesting at 2 and forbids indenting the first item.
@JsonKey(defaultValue: 0) int get indentLevel;/// Signed, root-relative picture of the item, or null. Resolve with
/// `AppConfig.mediaUrl`. Set and cleared through the dedicated image
/// endpoints - `UpdateTodoItem` cannot touch it.
 String? get imageUrl;/// Where to find it in the shop - "Aisle 7", "Bakery". Free text, null when
/// unset; the server never returns `""`. Cleared with `""` on the wire - see
/// `UpdateTodoItem.clearLocation`.
 String? get location;@UtcStamp() DateTime? get createdAt;@UtcStamp() DateTime? get completedAt;
/// Create a copy of TodoItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodoItemCopyWith<TodoItem> get copyWith => _$TodoItemCopyWithImpl<TodoItem>(this as TodoItem, _$identity);

  /// Serializes this TodoItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TodoItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodoItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.todoListId, _this.todoListId) || other.todoListId == _this.todoListId)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.isCompleted, _this.isCompleted) || other.isCompleted == _this.isCompleted)&&(identical(other.displayOrder, _this.displayOrder) || other.displayOrder == _this.displayOrder)&&(identical(other.indentLevel, _this.indentLevel) || other.indentLevel == _this.indentLevel)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TodoItem;
  return Object.hash(runtimeType,_this.id,_this.todoListId,_this.groupId,_this.content,_this.isCompleted,_this.displayOrder,_this.indentLevel,_this.imageUrl,_this.location,_this.createdAt,_this.completedAt);
}

@override
String toString() {
  final _this = this as TodoItem;
  return 'TodoItem(id: ${_this.id}, todoListId: ${_this.todoListId}, groupId: ${_this.groupId}, content: ${_this.content}, isCompleted: ${_this.isCompleted}, displayOrder: ${_this.displayOrder}, indentLevel: ${_this.indentLevel}, imageUrl: ${_this.imageUrl}, location: ${_this.location}, createdAt: ${_this.createdAt}, completedAt: ${_this.completedAt})';
}


}

/// @nodoc
abstract mixin class $TodoItemCopyWith<$Res>  {
  factory $TodoItemCopyWith(TodoItem value, $Res Function(TodoItem) _then) = _$TodoItemCopyWithImpl;
@useResult
$Res call({
 int id, int todoListId, int? groupId, String content,@JsonKey(defaultValue: false) bool isCompleted,@JsonKey(defaultValue: 0) int displayOrder,@JsonKey(defaultValue: 0) int indentLevel, String? imageUrl, String? location,@UtcStamp() DateTime? createdAt,@UtcStamp() DateTime? completedAt
});




}
/// @nodoc
class _$TodoItemCopyWithImpl<$Res>
    implements $TodoItemCopyWith<$Res> {
  _$TodoItemCopyWithImpl(this._self, this._then);

  final TodoItem _self;
  final $Res Function(TodoItem) _then;

/// Create a copy of TodoItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? todoListId = null,Object? groupId = freezed,Object? content = null,Object? isCompleted = null,Object? displayOrder = null,Object? indentLevel = null,Object? imageUrl = freezed,Object? location = freezed,Object? createdAt = freezed,Object? completedAt = freezed,}) {
  return _then(TodoItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,todoListId: null == todoListId ? _self.todoListId : todoListId // ignore: cast_nullable_to_non_nullable
as int,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,indentLevel: null == indentLevel ? _self.indentLevel : indentLevel // ignore: cast_nullable_to_non_nullable
as int,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TodoItem].
extension TodoItemPatterns on TodoItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TodoItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TodoItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TodoItem value)  $default,){
final _that = this;
switch (_that) {
case _TodoItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TodoItem value)?  $default,){
final _that = this;
switch (_that) {
case _TodoItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int todoListId,  int? groupId,  String content, @JsonKey(defaultValue: false)  bool isCompleted, @JsonKey(defaultValue: 0)  int displayOrder, @JsonKey(defaultValue: 0)  int indentLevel,  String? imageUrl,  String? location, @UtcStamp()  DateTime? createdAt, @UtcStamp()  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TodoItem() when $default != null:
return $default(_that.id,_that.todoListId,_that.groupId,_that.content,_that.isCompleted,_that.displayOrder,_that.indentLevel,_that.imageUrl,_that.location,_that.createdAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int todoListId,  int? groupId,  String content, @JsonKey(defaultValue: false)  bool isCompleted, @JsonKey(defaultValue: 0)  int displayOrder, @JsonKey(defaultValue: 0)  int indentLevel,  String? imageUrl,  String? location, @UtcStamp()  DateTime? createdAt, @UtcStamp()  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _TodoItem():
return $default(_that.id,_that.todoListId,_that.groupId,_that.content,_that.isCompleted,_that.displayOrder,_that.indentLevel,_that.imageUrl,_that.location,_that.createdAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int todoListId,  int? groupId,  String content, @JsonKey(defaultValue: false)  bool isCompleted, @JsonKey(defaultValue: 0)  int displayOrder, @JsonKey(defaultValue: 0)  int indentLevel,  String? imageUrl,  String? location, @UtcStamp()  DateTime? createdAt, @UtcStamp()  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _TodoItem() when $default != null:
return $default(_that.id,_that.todoListId,_that.groupId,_that.content,_that.isCompleted,_that.displayOrder,_that.indentLevel,_that.imageUrl,_that.location,_that.createdAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TodoItem implements TodoItem {
  const _TodoItem({required this.id, required this.todoListId, this.groupId, required this.content, @JsonKey(defaultValue: false) required this.isCompleted, @JsonKey(defaultValue: 0) required this.displayOrder, @JsonKey(defaultValue: 0) required this.indentLevel, this.imageUrl, this.location, @UtcStamp() this.createdAt, @UtcStamp() this.completedAt});
  factory _TodoItem.fromJson(Map<String, dynamic> json) => _$TodoItemFromJson(json);

@override final  int id;
@override final  int todoListId;
/// Null for an ungrouped item. Note that **sending** `groupId: 0` is what
/// removes an item from its group - see `UpdateTodoItem`.
@override final  int? groupId;
@override final  String content;
@override@JsonKey(defaultValue: false) final  bool isCompleted;
@override@JsonKey(defaultValue: 0) final  int displayOrder;
/// 0-2. The web UI caps nesting at 2 and forbids indenting the first item.
@override@JsonKey(defaultValue: 0) final  int indentLevel;
/// Signed, root-relative picture of the item, or null. Resolve with
/// `AppConfig.mediaUrl`. Set and cleared through the dedicated image
/// endpoints - `UpdateTodoItem` cannot touch it.
@override final  String? imageUrl;
/// Where to find it in the shop - "Aisle 7", "Bakery". Free text, null when
/// unset; the server never returns `""`. Cleared with `""` on the wire - see
/// `UpdateTodoItem.clearLocation`.
@override final  String? location;
@override@UtcStamp() final  DateTime? createdAt;
@override@UtcStamp() final  DateTime? completedAt;

/// Create a copy of TodoItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TodoItemCopyWith<_TodoItem> get copyWith => __$TodoItemCopyWithImpl<_TodoItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TodoItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TodoItem&&(identical(other.id, id) || other.id == id)&&(identical(other.todoListId, todoListId) || other.todoListId == todoListId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.content, content) || other.content == content)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&(identical(other.indentLevel, indentLevel) || other.indentLevel == indentLevel)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.location, location) || other.location == location)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,todoListId,groupId,content,isCompleted,displayOrder,indentLevel,imageUrl,location,createdAt,completedAt);
}

@override
String toString() {
    return 'TodoItem(id: $id, todoListId: $todoListId, groupId: $groupId, content: $content, isCompleted: $isCompleted, displayOrder: $displayOrder, indentLevel: $indentLevel, imageUrl: $imageUrl, location: $location, createdAt: $createdAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$TodoItemCopyWith<$Res> implements $TodoItemCopyWith<$Res> {
  factory _$TodoItemCopyWith(_TodoItem value, $Res Function(_TodoItem) _then) = __$TodoItemCopyWithImpl;
@override @useResult
$Res call({
 int id, int todoListId, int? groupId, String content,@JsonKey(defaultValue: false) bool isCompleted,@JsonKey(defaultValue: 0) int displayOrder,@JsonKey(defaultValue: 0) int indentLevel, String? imageUrl, String? location,@UtcStamp() DateTime? createdAt,@UtcStamp() DateTime? completedAt
});




}
/// @nodoc
class __$TodoItemCopyWithImpl<$Res>
    implements _$TodoItemCopyWith<$Res> {
  __$TodoItemCopyWithImpl(this._self, this._then);

  final _TodoItem _self;
  final $Res Function(_TodoItem) _then;

/// Create a copy of TodoItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? todoListId = null,Object? groupId = freezed,Object? content = null,Object? isCompleted = null,Object? displayOrder = null,Object? indentLevel = null,Object? imageUrl = freezed,Object? location = freezed,Object? createdAt = freezed,Object? completedAt = freezed,}) {
  return _then(_TodoItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,todoListId: null == todoListId ? _self.todoListId : todoListId // ignore: cast_nullable_to_non_nullable
as int,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,indentLevel: null == indentLevel ? _self.indentLevel : indentLevel // ignore: cast_nullable_to_non_nullable
as int,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$TodoItemGroup {

 int get id; int get todoListId; String get name;@JsonKey(defaultValue: 0) int get displayOrder;@JsonKey(defaultValue: <TodoItem>[]) List<TodoItem> get items;
/// Create a copy of TodoItemGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodoItemGroupCopyWith<TodoItemGroup> get copyWith => _$TodoItemGroupCopyWithImpl<TodoItemGroup>(this as TodoItemGroup, _$identity);

  /// Serializes this TodoItemGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TodoItemGroup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodoItemGroup&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.todoListId, _this.todoListId) || other.todoListId == _this.todoListId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.displayOrder, _this.displayOrder) || other.displayOrder == _this.displayOrder)&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TodoItemGroup;
  return Object.hash(runtimeType,_this.id,_this.todoListId,_this.name,_this.displayOrder,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as TodoItemGroup;
  return 'TodoItemGroup(id: ${_this.id}, todoListId: ${_this.todoListId}, name: ${_this.name}, displayOrder: ${_this.displayOrder}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $TodoItemGroupCopyWith<$Res>  {
  factory $TodoItemGroupCopyWith(TodoItemGroup value, $Res Function(TodoItemGroup) _then) = _$TodoItemGroupCopyWithImpl;
@useResult
$Res call({
 int id, int todoListId, String name,@JsonKey(defaultValue: 0) int displayOrder,@JsonKey(defaultValue: <TodoItem>[]) List<TodoItem> items
});




}
/// @nodoc
class _$TodoItemGroupCopyWithImpl<$Res>
    implements $TodoItemGroupCopyWith<$Res> {
  _$TodoItemGroupCopyWithImpl(this._self, this._then);

  final TodoItemGroup _self;
  final $Res Function(TodoItemGroup) _then;

/// Create a copy of TodoItemGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? todoListId = null,Object? name = null,Object? displayOrder = null,Object? items = null,}) {
  return _then(TodoItemGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,todoListId: null == todoListId ? _self.todoListId : todoListId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TodoItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [TodoItemGroup].
extension TodoItemGroupPatterns on TodoItemGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TodoItemGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TodoItemGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TodoItemGroup value)  $default,){
final _that = this;
switch (_that) {
case _TodoItemGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TodoItemGroup value)?  $default,){
final _that = this;
switch (_that) {
case _TodoItemGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int todoListId,  String name, @JsonKey(defaultValue: 0)  int displayOrder, @JsonKey(defaultValue: <TodoItem>[])  List<TodoItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TodoItemGroup() when $default != null:
return $default(_that.id,_that.todoListId,_that.name,_that.displayOrder,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int todoListId,  String name, @JsonKey(defaultValue: 0)  int displayOrder, @JsonKey(defaultValue: <TodoItem>[])  List<TodoItem> items)  $default,) {final _that = this;
switch (_that) {
case _TodoItemGroup():
return $default(_that.id,_that.todoListId,_that.name,_that.displayOrder,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int todoListId,  String name, @JsonKey(defaultValue: 0)  int displayOrder, @JsonKey(defaultValue: <TodoItem>[])  List<TodoItem> items)?  $default,) {final _that = this;
switch (_that) {
case _TodoItemGroup() when $default != null:
return $default(_that.id,_that.todoListId,_that.name,_that.displayOrder,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TodoItemGroup implements TodoItemGroup {
  const _TodoItemGroup({required this.id, required this.todoListId, required this.name, @JsonKey(defaultValue: 0) required this.displayOrder, @JsonKey(defaultValue: <TodoItem>[]) required  List<TodoItem> items}): _items = items;
  factory _TodoItemGroup.fromJson(Map<String, dynamic> json) => _$TodoItemGroupFromJson(json);

@override final  int id;
@override final  int todoListId;
@override final  String name;
@override@JsonKey(defaultValue: 0) final  int displayOrder;
 final  List<TodoItem> _items;
@override@JsonKey(defaultValue: <TodoItem>[]) List<TodoItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of TodoItemGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TodoItemGroupCopyWith<_TodoItemGroup> get copyWith => __$TodoItemGroupCopyWithImpl<_TodoItemGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TodoItemGroupToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TodoItemGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.todoListId, todoListId) || other.todoListId == todoListId)&&(identical(other.name, name) || other.name == name)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,todoListId,name,displayOrder,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'TodoItemGroup(id: $id, todoListId: $todoListId, name: $name, displayOrder: $displayOrder, items: $items)';
}


}

/// @nodoc
abstract mixin class _$TodoItemGroupCopyWith<$Res> implements $TodoItemGroupCopyWith<$Res> {
  factory _$TodoItemGroupCopyWith(_TodoItemGroup value, $Res Function(_TodoItemGroup) _then) = __$TodoItemGroupCopyWithImpl;
@override @useResult
$Res call({
 int id, int todoListId, String name,@JsonKey(defaultValue: 0) int displayOrder,@JsonKey(defaultValue: <TodoItem>[]) List<TodoItem> items
});




}
/// @nodoc
class __$TodoItemGroupCopyWithImpl<$Res>
    implements _$TodoItemGroupCopyWith<$Res> {
  __$TodoItemGroupCopyWithImpl(this._self, this._then);

  final _TodoItemGroup _self;
  final $Res Function(_TodoItemGroup) _then;

/// Create a copy of TodoItemGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? todoListId = null,Object? name = null,Object? displayOrder = null,Object? items = null,}) {
  return _then(_TodoItemGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,todoListId: null == todoListId ? _self.todoListId : todoListId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TodoItem>,
  ));
}


}


/// @nodoc
mixin _$TodoLabel {

 int get id; String get name; String? get color;@JsonKey(defaultValue: 0) int get listCount;
/// Create a copy of TodoLabel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodoLabelCopyWith<TodoLabel> get copyWith => _$TodoLabelCopyWithImpl<TodoLabel>(this as TodoLabel, _$identity);

  /// Serializes this TodoLabel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TodoLabel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodoLabel&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.listCount, _this.listCount) || other.listCount == _this.listCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TodoLabel;
  return Object.hash(runtimeType,_this.id,_this.name,_this.color,_this.listCount);
}

@override
String toString() {
  final _this = this as TodoLabel;
  return 'TodoLabel(id: ${_this.id}, name: ${_this.name}, color: ${_this.color}, listCount: ${_this.listCount})';
}


}

/// @nodoc
abstract mixin class $TodoLabelCopyWith<$Res>  {
  factory $TodoLabelCopyWith(TodoLabel value, $Res Function(TodoLabel) _then) = _$TodoLabelCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? color,@JsonKey(defaultValue: 0) int listCount
});




}
/// @nodoc
class _$TodoLabelCopyWithImpl<$Res>
    implements $TodoLabelCopyWith<$Res> {
  _$TodoLabelCopyWithImpl(this._self, this._then);

  final TodoLabel _self;
  final $Res Function(TodoLabel) _then;

/// Create a copy of TodoLabel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? color = freezed,Object? listCount = null,}) {
  return _then(TodoLabel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,listCount: null == listCount ? _self.listCount : listCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TodoLabel].
extension TodoLabelPatterns on TodoLabel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TodoLabel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TodoLabel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TodoLabel value)  $default,){
final _that = this;
switch (_that) {
case _TodoLabel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TodoLabel value)?  $default,){
final _that = this;
switch (_that) {
case _TodoLabel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? color, @JsonKey(defaultValue: 0)  int listCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TodoLabel() when $default != null:
return $default(_that.id,_that.name,_that.color,_that.listCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? color, @JsonKey(defaultValue: 0)  int listCount)  $default,) {final _that = this;
switch (_that) {
case _TodoLabel():
return $default(_that.id,_that.name,_that.color,_that.listCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? color, @JsonKey(defaultValue: 0)  int listCount)?  $default,) {final _that = this;
switch (_that) {
case _TodoLabel() when $default != null:
return $default(_that.id,_that.name,_that.color,_that.listCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TodoLabel implements TodoLabel {
  const _TodoLabel({required this.id, required this.name, this.color, @JsonKey(defaultValue: 0) required this.listCount});
  factory _TodoLabel.fromJson(Map<String, dynamic> json) => _$TodoLabelFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? color;
@override@JsonKey(defaultValue: 0) final  int listCount;

/// Create a copy of TodoLabel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TodoLabelCopyWith<_TodoLabel> get copyWith => __$TodoLabelCopyWithImpl<_TodoLabel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TodoLabelToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TodoLabel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.listCount, listCount) || other.listCount == listCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,color,listCount);
}

@override
String toString() {
    return 'TodoLabel(id: $id, name: $name, color: $color, listCount: $listCount)';
}


}

/// @nodoc
abstract mixin class _$TodoLabelCopyWith<$Res> implements $TodoLabelCopyWith<$Res> {
  factory _$TodoLabelCopyWith(_TodoLabel value, $Res Function(_TodoLabel) _then) = __$TodoLabelCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? color,@JsonKey(defaultValue: 0) int listCount
});




}
/// @nodoc
class __$TodoLabelCopyWithImpl<$Res>
    implements _$TodoLabelCopyWith<$Res> {
  __$TodoLabelCopyWithImpl(this._self, this._then);

  final _TodoLabel _self;
  final $Res Function(_TodoLabel) _then;

/// Create a copy of TodoLabel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? color = freezed,Object? listCount = null,}) {
  return _then(_TodoLabel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,listCount: null == listCount ? _self.listCount : listCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$LinkedEvent {

 String get eventId; String? get eventTitle;@RequiredWallClock() DateTime get eventStart;@WallClock() DateTime? get eventEnd;@JsonKey(defaultValue: false) bool get isAllDay;
/// Create a copy of LinkedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkedEventCopyWith<LinkedEvent> get copyWith => _$LinkedEventCopyWithImpl<LinkedEvent>(this as LinkedEvent, _$identity);

  /// Serializes this LinkedEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LinkedEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkedEvent&&(identical(other.eventId, _this.eventId) || other.eventId == _this.eventId)&&(identical(other.eventTitle, _this.eventTitle) || other.eventTitle == _this.eventTitle)&&(identical(other.eventStart, _this.eventStart) || other.eventStart == _this.eventStart)&&(identical(other.eventEnd, _this.eventEnd) || other.eventEnd == _this.eventEnd)&&(identical(other.isAllDay, _this.isAllDay) || other.isAllDay == _this.isAllDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LinkedEvent;
  return Object.hash(runtimeType,_this.eventId,_this.eventTitle,_this.eventStart,_this.eventEnd,_this.isAllDay);
}

@override
String toString() {
  final _this = this as LinkedEvent;
  return 'LinkedEvent(eventId: ${_this.eventId}, eventTitle: ${_this.eventTitle}, eventStart: ${_this.eventStart}, eventEnd: ${_this.eventEnd}, isAllDay: ${_this.isAllDay})';
}


}

/// @nodoc
abstract mixin class $LinkedEventCopyWith<$Res>  {
  factory $LinkedEventCopyWith(LinkedEvent value, $Res Function(LinkedEvent) _then) = _$LinkedEventCopyWithImpl;
@useResult
$Res call({
 String eventId, String? eventTitle,@RequiredWallClock() DateTime eventStart,@WallClock() DateTime? eventEnd,@JsonKey(defaultValue: false) bool isAllDay
});




}
/// @nodoc
class _$LinkedEventCopyWithImpl<$Res>
    implements $LinkedEventCopyWith<$Res> {
  _$LinkedEventCopyWithImpl(this._self, this._then);

  final LinkedEvent _self;
  final $Res Function(LinkedEvent) _then;

/// Create a copy of LinkedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? eventTitle = freezed,Object? eventStart = null,Object? eventEnd = freezed,Object? isAllDay = null,}) {
  return _then(LinkedEvent(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,eventTitle: freezed == eventTitle ? _self.eventTitle : eventTitle // ignore: cast_nullable_to_non_nullable
as String?,eventStart: null == eventStart ? _self.eventStart : eventStart // ignore: cast_nullable_to_non_nullable
as DateTime,eventEnd: freezed == eventEnd ? _self.eventEnd : eventEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,isAllDay: null == isAllDay ? _self.isAllDay : isAllDay // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LinkedEvent].
extension LinkedEventPatterns on LinkedEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinkedEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinkedEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinkedEvent value)  $default,){
final _that = this;
switch (_that) {
case _LinkedEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinkedEvent value)?  $default,){
final _that = this;
switch (_that) {
case _LinkedEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  String? eventTitle, @RequiredWallClock()  DateTime eventStart, @WallClock()  DateTime? eventEnd, @JsonKey(defaultValue: false)  bool isAllDay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinkedEvent() when $default != null:
return $default(_that.eventId,_that.eventTitle,_that.eventStart,_that.eventEnd,_that.isAllDay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  String? eventTitle, @RequiredWallClock()  DateTime eventStart, @WallClock()  DateTime? eventEnd, @JsonKey(defaultValue: false)  bool isAllDay)  $default,) {final _that = this;
switch (_that) {
case _LinkedEvent():
return $default(_that.eventId,_that.eventTitle,_that.eventStart,_that.eventEnd,_that.isAllDay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  String? eventTitle, @RequiredWallClock()  DateTime eventStart, @WallClock()  DateTime? eventEnd, @JsonKey(defaultValue: false)  bool isAllDay)?  $default,) {final _that = this;
switch (_that) {
case _LinkedEvent() when $default != null:
return $default(_that.eventId,_that.eventTitle,_that.eventStart,_that.eventEnd,_that.isAllDay);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LinkedEvent implements LinkedEvent {
  const _LinkedEvent({required this.eventId, this.eventTitle, @RequiredWallClock() required this.eventStart, @WallClock() this.eventEnd, @JsonKey(defaultValue: false) required this.isAllDay});
  factory _LinkedEvent.fromJson(Map<String, dynamic> json) => _$LinkedEventFromJson(json);

@override final  String eventId;
@override final  String? eventTitle;
@override@RequiredWallClock() final  DateTime eventStart;
@override@WallClock() final  DateTime? eventEnd;
@override@JsonKey(defaultValue: false) final  bool isAllDay;

/// Create a copy of LinkedEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinkedEventCopyWith<_LinkedEvent> get copyWith => __$LinkedEventCopyWithImpl<_LinkedEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LinkedEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinkedEvent&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.eventTitle, eventTitle) || other.eventTitle == eventTitle)&&(identical(other.eventStart, eventStart) || other.eventStart == eventStart)&&(identical(other.eventEnd, eventEnd) || other.eventEnd == eventEnd)&&(identical(other.isAllDay, isAllDay) || other.isAllDay == isAllDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,eventId,eventTitle,eventStart,eventEnd,isAllDay);
}

@override
String toString() {
    return 'LinkedEvent(eventId: $eventId, eventTitle: $eventTitle, eventStart: $eventStart, eventEnd: $eventEnd, isAllDay: $isAllDay)';
}


}

/// @nodoc
abstract mixin class _$LinkedEventCopyWith<$Res> implements $LinkedEventCopyWith<$Res> {
  factory _$LinkedEventCopyWith(_LinkedEvent value, $Res Function(_LinkedEvent) _then) = __$LinkedEventCopyWithImpl;
@override @useResult
$Res call({
 String eventId, String? eventTitle,@RequiredWallClock() DateTime eventStart,@WallClock() DateTime? eventEnd,@JsonKey(defaultValue: false) bool isAllDay
});




}
/// @nodoc
class __$LinkedEventCopyWithImpl<$Res>
    implements _$LinkedEventCopyWith<$Res> {
  __$LinkedEventCopyWithImpl(this._self, this._then);

  final _LinkedEvent _self;
  final $Res Function(_LinkedEvent) _then;

/// Create a copy of LinkedEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? eventTitle = freezed,Object? eventStart = null,Object? eventEnd = freezed,Object? isAllDay = null,}) {
  return _then(_LinkedEvent(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,eventTitle: freezed == eventTitle ? _self.eventTitle : eventTitle // ignore: cast_nullable_to_non_nullable
as String?,eventStart: null == eventStart ? _self.eventStart : eventStart // ignore: cast_nullable_to_non_nullable
as DateTime,eventEnd: freezed == eventEnd ? _self.eventEnd : eventEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,isAllDay: null == isAllDay ? _self.isAllDay : isAllDay // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$TodoList {

 int get id; String get title; String? get color;@JsonKey(defaultValue: false) bool get isPinned;@JsonKey(defaultValue: false) bool get isArchived;@JsonKey(defaultValue: 0) int get displayOrder;@UtcStamp() DateTime? get createdAt;@UtcStamp() DateTime? get updatedAt;@WallClock() DateTime? get reminderDateTime;/// An `"HH:mm"` **string**, not a timestamp. Use [scheduledMinutes].
 String? get scheduledTime;/// CSV of `0`=Sunday..`6`=Saturday. Null or empty means every day.
 String? get scheduledDays; String? get personId; String? get personName;/// **Ungrouped items only.** Items that belong to a group live in
/// `groups[].items`. Use [allItems] unless you specifically want the
/// ungrouped ones - rendering this list alone silently drops every grouped
/// item, which is the easiest mistake to make against this API.
@JsonKey(defaultValue: <TodoItem>[]) List<TodoItem> get items;@JsonKey(defaultValue: <TodoItemGroup>[]) List<TodoItemGroup> get groups;@JsonKey(defaultValue: <TodoLabel>[]) List<TodoLabel> get labels;/// Counts **all** items, grouped and ungrouped.
@JsonKey(defaultValue: 0) int get totalItems;@JsonKey(defaultValue: 0) int get completedItems; LinkedEvent? get linkedEvent;
/// Create a copy of TodoList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodoListCopyWith<TodoList> get copyWith => _$TodoListCopyWithImpl<TodoList>(this as TodoList, _$identity);

  /// Serializes this TodoList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TodoList;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodoList&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.isPinned, _this.isPinned) || other.isPinned == _this.isPinned)&&(identical(other.isArchived, _this.isArchived) || other.isArchived == _this.isArchived)&&(identical(other.displayOrder, _this.displayOrder) || other.displayOrder == _this.displayOrder)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.reminderDateTime, _this.reminderDateTime) || other.reminderDateTime == _this.reminderDateTime)&&(identical(other.scheduledTime, _this.scheduledTime) || other.scheduledTime == _this.scheduledTime)&&(identical(other.scheduledDays, _this.scheduledDays) || other.scheduledDays == _this.scheduledDays)&&(identical(other.personId, _this.personId) || other.personId == _this.personId)&&(identical(other.personName, _this.personName) || other.personName == _this.personName)&&const DeepCollectionEquality().equals(other.items, _this.items)&&const DeepCollectionEquality().equals(other.groups, _this.groups)&&const DeepCollectionEquality().equals(other.labels, _this.labels)&&(identical(other.totalItems, _this.totalItems) || other.totalItems == _this.totalItems)&&(identical(other.completedItems, _this.completedItems) || other.completedItems == _this.completedItems)&&(identical(other.linkedEvent, _this.linkedEvent) || other.linkedEvent == _this.linkedEvent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TodoList;
  return Object.hashAll([runtimeType,_this.id,_this.title,_this.color,_this.isPinned,_this.isArchived,_this.displayOrder,_this.createdAt,_this.updatedAt,_this.reminderDateTime,_this.scheduledTime,_this.scheduledDays,_this.personId,_this.personName,const DeepCollectionEquality().hash(_this.items),const DeepCollectionEquality().hash(_this.groups),const DeepCollectionEquality().hash(_this.labels),_this.totalItems,_this.completedItems,_this.linkedEvent]);
}

@override
String toString() {
  final _this = this as TodoList;
  return 'TodoList(id: ${_this.id}, title: ${_this.title}, color: ${_this.color}, isPinned: ${_this.isPinned}, isArchived: ${_this.isArchived}, displayOrder: ${_this.displayOrder}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, reminderDateTime: ${_this.reminderDateTime}, scheduledTime: ${_this.scheduledTime}, scheduledDays: ${_this.scheduledDays}, personId: ${_this.personId}, personName: ${_this.personName}, items: ${_this.items}, groups: ${_this.groups}, labels: ${_this.labels}, totalItems: ${_this.totalItems}, completedItems: ${_this.completedItems}, linkedEvent: ${_this.linkedEvent})';
}


}

/// @nodoc
abstract mixin class $TodoListCopyWith<$Res>  {
  factory $TodoListCopyWith(TodoList value, $Res Function(TodoList) _then) = _$TodoListCopyWithImpl;
@useResult
$Res call({
 int id, String title, String? color,@JsonKey(defaultValue: false) bool isPinned,@JsonKey(defaultValue: false) bool isArchived,@JsonKey(defaultValue: 0) int displayOrder,@UtcStamp() DateTime? createdAt,@UtcStamp() DateTime? updatedAt,@WallClock() DateTime? reminderDateTime, String? scheduledTime, String? scheduledDays, String? personId, String? personName,@JsonKey(defaultValue: <TodoItem>[]) List<TodoItem> items,@JsonKey(defaultValue: <TodoItemGroup>[]) List<TodoItemGroup> groups,@JsonKey(defaultValue: <TodoLabel>[]) List<TodoLabel> labels,@JsonKey(defaultValue: 0) int totalItems,@JsonKey(defaultValue: 0) int completedItems, LinkedEvent? linkedEvent
});


$LinkedEventCopyWith<$Res>? get linkedEvent;

}
/// @nodoc
class _$TodoListCopyWithImpl<$Res>
    implements $TodoListCopyWith<$Res> {
  _$TodoListCopyWithImpl(this._self, this._then);

  final TodoList _self;
  final $Res Function(TodoList) _then;

/// Create a copy of TodoList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? color = freezed,Object? isPinned = null,Object? isArchived = null,Object? displayOrder = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? reminderDateTime = freezed,Object? scheduledTime = freezed,Object? scheduledDays = freezed,Object? personId = freezed,Object? personName = freezed,Object? items = null,Object? groups = null,Object? labels = null,Object? totalItems = null,Object? completedItems = null,Object? linkedEvent = freezed,}) {
  return _then(TodoList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reminderDateTime: freezed == reminderDateTime ? _self.reminderDateTime : reminderDateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,scheduledTime: freezed == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as String?,scheduledDays: freezed == scheduledDays ? _self.scheduledDays : scheduledDays // ignore: cast_nullable_to_non_nullable
as String?,personId: freezed == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String?,personName: freezed == personName ? _self.personName : personName // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TodoItem>,groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as List<TodoItemGroup>,labels: null == labels ? _self.labels : labels // ignore: cast_nullable_to_non_nullable
as List<TodoLabel>,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,completedItems: null == completedItems ? _self.completedItems : completedItems // ignore: cast_nullable_to_non_nullable
as int,linkedEvent: freezed == linkedEvent ? _self.linkedEvent : linkedEvent // ignore: cast_nullable_to_non_nullable
as LinkedEvent?,
  ));
}
/// Create a copy of TodoList
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LinkedEventCopyWith<$Res>? get linkedEvent {
    if (_self.linkedEvent == null) {
    return null;
  }

  return $LinkedEventCopyWith<$Res>(_self.linkedEvent!, (value) {
    return _then(_self.copyWith(linkedEvent: value));
  });
}
}


/// Adds pattern-matching-related methods to [TodoList].
extension TodoListPatterns on TodoList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TodoList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TodoList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TodoList value)  $default,){
final _that = this;
switch (_that) {
case _TodoList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TodoList value)?  $default,){
final _that = this;
switch (_that) {
case _TodoList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String? color, @JsonKey(defaultValue: false)  bool isPinned, @JsonKey(defaultValue: false)  bool isArchived, @JsonKey(defaultValue: 0)  int displayOrder, @UtcStamp()  DateTime? createdAt, @UtcStamp()  DateTime? updatedAt, @WallClock()  DateTime? reminderDateTime,  String? scheduledTime,  String? scheduledDays,  String? personId,  String? personName, @JsonKey(defaultValue: <TodoItem>[])  List<TodoItem> items, @JsonKey(defaultValue: <TodoItemGroup>[])  List<TodoItemGroup> groups, @JsonKey(defaultValue: <TodoLabel>[])  List<TodoLabel> labels, @JsonKey(defaultValue: 0)  int totalItems, @JsonKey(defaultValue: 0)  int completedItems,  LinkedEvent? linkedEvent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TodoList() when $default != null:
return $default(_that.id,_that.title,_that.color,_that.isPinned,_that.isArchived,_that.displayOrder,_that.createdAt,_that.updatedAt,_that.reminderDateTime,_that.scheduledTime,_that.scheduledDays,_that.personId,_that.personName,_that.items,_that.groups,_that.labels,_that.totalItems,_that.completedItems,_that.linkedEvent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String? color, @JsonKey(defaultValue: false)  bool isPinned, @JsonKey(defaultValue: false)  bool isArchived, @JsonKey(defaultValue: 0)  int displayOrder, @UtcStamp()  DateTime? createdAt, @UtcStamp()  DateTime? updatedAt, @WallClock()  DateTime? reminderDateTime,  String? scheduledTime,  String? scheduledDays,  String? personId,  String? personName, @JsonKey(defaultValue: <TodoItem>[])  List<TodoItem> items, @JsonKey(defaultValue: <TodoItemGroup>[])  List<TodoItemGroup> groups, @JsonKey(defaultValue: <TodoLabel>[])  List<TodoLabel> labels, @JsonKey(defaultValue: 0)  int totalItems, @JsonKey(defaultValue: 0)  int completedItems,  LinkedEvent? linkedEvent)  $default,) {final _that = this;
switch (_that) {
case _TodoList():
return $default(_that.id,_that.title,_that.color,_that.isPinned,_that.isArchived,_that.displayOrder,_that.createdAt,_that.updatedAt,_that.reminderDateTime,_that.scheduledTime,_that.scheduledDays,_that.personId,_that.personName,_that.items,_that.groups,_that.labels,_that.totalItems,_that.completedItems,_that.linkedEvent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String? color, @JsonKey(defaultValue: false)  bool isPinned, @JsonKey(defaultValue: false)  bool isArchived, @JsonKey(defaultValue: 0)  int displayOrder, @UtcStamp()  DateTime? createdAt, @UtcStamp()  DateTime? updatedAt, @WallClock()  DateTime? reminderDateTime,  String? scheduledTime,  String? scheduledDays,  String? personId,  String? personName, @JsonKey(defaultValue: <TodoItem>[])  List<TodoItem> items, @JsonKey(defaultValue: <TodoItemGroup>[])  List<TodoItemGroup> groups, @JsonKey(defaultValue: <TodoLabel>[])  List<TodoLabel> labels, @JsonKey(defaultValue: 0)  int totalItems, @JsonKey(defaultValue: 0)  int completedItems,  LinkedEvent? linkedEvent)?  $default,) {final _that = this;
switch (_that) {
case _TodoList() when $default != null:
return $default(_that.id,_that.title,_that.color,_that.isPinned,_that.isArchived,_that.displayOrder,_that.createdAt,_that.updatedAt,_that.reminderDateTime,_that.scheduledTime,_that.scheduledDays,_that.personId,_that.personName,_that.items,_that.groups,_that.labels,_that.totalItems,_that.completedItems,_that.linkedEvent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TodoList extends TodoList {
  const _TodoList({required this.id, required this.title, this.color, @JsonKey(defaultValue: false) required this.isPinned, @JsonKey(defaultValue: false) required this.isArchived, @JsonKey(defaultValue: 0) required this.displayOrder, @UtcStamp() this.createdAt, @UtcStamp() this.updatedAt, @WallClock() this.reminderDateTime, this.scheduledTime, this.scheduledDays, this.personId, this.personName, @JsonKey(defaultValue: <TodoItem>[]) required  List<TodoItem> items, @JsonKey(defaultValue: <TodoItemGroup>[]) required  List<TodoItemGroup> groups, @JsonKey(defaultValue: <TodoLabel>[]) required  List<TodoLabel> labels, @JsonKey(defaultValue: 0) required this.totalItems, @JsonKey(defaultValue: 0) required this.completedItems, this.linkedEvent}): _items = items,_groups = groups,_labels = labels,super._();
  factory _TodoList.fromJson(Map<String, dynamic> json) => _$TodoListFromJson(json);

@override final  int id;
@override final  String title;
@override final  String? color;
@override@JsonKey(defaultValue: false) final  bool isPinned;
@override@JsonKey(defaultValue: false) final  bool isArchived;
@override@JsonKey(defaultValue: 0) final  int displayOrder;
@override@UtcStamp() final  DateTime? createdAt;
@override@UtcStamp() final  DateTime? updatedAt;
@override@WallClock() final  DateTime? reminderDateTime;
/// An `"HH:mm"` **string**, not a timestamp. Use [scheduledMinutes].
@override final  String? scheduledTime;
/// CSV of `0`=Sunday..`6`=Saturday. Null or empty means every day.
@override final  String? scheduledDays;
@override final  String? personId;
@override final  String? personName;
/// **Ungrouped items only.** Items that belong to a group live in
/// `groups[].items`. Use [allItems] unless you specifically want the
/// ungrouped ones - rendering this list alone silently drops every grouped
/// item, which is the easiest mistake to make against this API.
 final  List<TodoItem> _items;
/// **Ungrouped items only.** Items that belong to a group live in
/// `groups[].items`. Use [allItems] unless you specifically want the
/// ungrouped ones - rendering this list alone silently drops every grouped
/// item, which is the easiest mistake to make against this API.
@override@JsonKey(defaultValue: <TodoItem>[]) List<TodoItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  List<TodoItemGroup> _groups;
@override@JsonKey(defaultValue: <TodoItemGroup>[]) List<TodoItemGroup> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}

 final  List<TodoLabel> _labels;
@override@JsonKey(defaultValue: <TodoLabel>[]) List<TodoLabel> get labels {
  if (_labels is EqualUnmodifiableListView) return _labels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_labels);
}

/// Counts **all** items, grouped and ungrouped.
@override@JsonKey(defaultValue: 0) final  int totalItems;
@override@JsonKey(defaultValue: 0) final  int completedItems;
@override final  LinkedEvent? linkedEvent;

/// Create a copy of TodoList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TodoListCopyWith<_TodoList> get copyWith => __$TodoListCopyWithImpl<_TodoList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TodoListToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TodoList&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.color, color) || other.color == color)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.reminderDateTime, reminderDateTime) || other.reminderDateTime == reminderDateTime)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.scheduledDays, scheduledDays) || other.scheduledDays == scheduledDays)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.personName, personName) || other.personName == personName)&&const DeepCollectionEquality().equals(other.items, _items)&&const DeepCollectionEquality().equals(other.groups, _groups)&&const DeepCollectionEquality().equals(other.labels, _labels)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.completedItems, completedItems) || other.completedItems == completedItems)&&(identical(other.linkedEvent, linkedEvent) || other.linkedEvent == linkedEvent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,title,color,isPinned,isArchived,displayOrder,createdAt,updatedAt,reminderDateTime,scheduledTime,scheduledDays,personId,personName,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_groups),const DeepCollectionEquality().hash(_labels),totalItems,completedItems,linkedEvent]);
}

@override
String toString() {
    return 'TodoList(id: $id, title: $title, color: $color, isPinned: $isPinned, isArchived: $isArchived, displayOrder: $displayOrder, createdAt: $createdAt, updatedAt: $updatedAt, reminderDateTime: $reminderDateTime, scheduledTime: $scheduledTime, scheduledDays: $scheduledDays, personId: $personId, personName: $personName, items: $items, groups: $groups, labels: $labels, totalItems: $totalItems, completedItems: $completedItems, linkedEvent: $linkedEvent)';
}


}

/// @nodoc
abstract mixin class _$TodoListCopyWith<$Res> implements $TodoListCopyWith<$Res> {
  factory _$TodoListCopyWith(_TodoList value, $Res Function(_TodoList) _then) = __$TodoListCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String? color,@JsonKey(defaultValue: false) bool isPinned,@JsonKey(defaultValue: false) bool isArchived,@JsonKey(defaultValue: 0) int displayOrder,@UtcStamp() DateTime? createdAt,@UtcStamp() DateTime? updatedAt,@WallClock() DateTime? reminderDateTime, String? scheduledTime, String? scheduledDays, String? personId, String? personName,@JsonKey(defaultValue: <TodoItem>[]) List<TodoItem> items,@JsonKey(defaultValue: <TodoItemGroup>[]) List<TodoItemGroup> groups,@JsonKey(defaultValue: <TodoLabel>[]) List<TodoLabel> labels,@JsonKey(defaultValue: 0) int totalItems,@JsonKey(defaultValue: 0) int completedItems, LinkedEvent? linkedEvent
});


@override $LinkedEventCopyWith<$Res>? get linkedEvent;

}
/// @nodoc
class __$TodoListCopyWithImpl<$Res>
    implements _$TodoListCopyWith<$Res> {
  __$TodoListCopyWithImpl(this._self, this._then);

  final _TodoList _self;
  final $Res Function(_TodoList) _then;

/// Create a copy of TodoList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? color = freezed,Object? isPinned = null,Object? isArchived = null,Object? displayOrder = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? reminderDateTime = freezed,Object? scheduledTime = freezed,Object? scheduledDays = freezed,Object? personId = freezed,Object? personName = freezed,Object? items = null,Object? groups = null,Object? labels = null,Object? totalItems = null,Object? completedItems = null,Object? linkedEvent = freezed,}) {
  return _then(_TodoList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reminderDateTime: freezed == reminderDateTime ? _self.reminderDateTime : reminderDateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,scheduledTime: freezed == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as String?,scheduledDays: freezed == scheduledDays ? _self.scheduledDays : scheduledDays // ignore: cast_nullable_to_non_nullable
as String?,personId: freezed == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String?,personName: freezed == personName ? _self.personName : personName // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TodoItem>,groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<TodoItemGroup>,labels: null == labels ? _self._labels : labels // ignore: cast_nullable_to_non_nullable
as List<TodoLabel>,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,completedItems: null == completedItems ? _self.completedItems : completedItems // ignore: cast_nullable_to_non_nullable
as int,linkedEvent: freezed == linkedEvent ? _self.linkedEvent : linkedEvent // ignore: cast_nullable_to_non_nullable
as LinkedEvent?,
  ));
}

/// Create a copy of TodoList
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LinkedEventCopyWith<$Res>? get linkedEvent {
    if (_self.linkedEvent == null) {
    return null;
  }

  return $LinkedEventCopyWith<$Res>(_self.linkedEvent!, (value) {
    return _then(_self.copyWith(linkedEvent: value));
  });
}
}


/// @nodoc
mixin _$CreateTodoList {

 String get title; String? get color; String? get personId;@WallClock() DateTime? get reminderDateTime; String? get scheduledTime; String? get scheduledDays;/// Optional seed items. Ungrouped, order preserved.
 List<CreateTodoItem>? get items;
/// Create a copy of CreateTodoList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateTodoListCopyWith<CreateTodoList> get copyWith => _$CreateTodoListCopyWithImpl<CreateTodoList>(this as CreateTodoList, _$identity);

  /// Serializes this CreateTodoList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CreateTodoList;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTodoList&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.personId, _this.personId) || other.personId == _this.personId)&&(identical(other.reminderDateTime, _this.reminderDateTime) || other.reminderDateTime == _this.reminderDateTime)&&(identical(other.scheduledTime, _this.scheduledTime) || other.scheduledTime == _this.scheduledTime)&&(identical(other.scheduledDays, _this.scheduledDays) || other.scheduledDays == _this.scheduledDays)&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CreateTodoList;
  return Object.hash(runtimeType,_this.title,_this.color,_this.personId,_this.reminderDateTime,_this.scheduledTime,_this.scheduledDays,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as CreateTodoList;
  return 'CreateTodoList(title: ${_this.title}, color: ${_this.color}, personId: ${_this.personId}, reminderDateTime: ${_this.reminderDateTime}, scheduledTime: ${_this.scheduledTime}, scheduledDays: ${_this.scheduledDays}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $CreateTodoListCopyWith<$Res>  {
  factory $CreateTodoListCopyWith(CreateTodoList value, $Res Function(CreateTodoList) _then) = _$CreateTodoListCopyWithImpl;
@useResult
$Res call({
 String title, String? color, String? personId,@WallClock() DateTime? reminderDateTime, String? scheduledTime, String? scheduledDays, List<CreateTodoItem>? items
});




}
/// @nodoc
class _$CreateTodoListCopyWithImpl<$Res>
    implements $CreateTodoListCopyWith<$Res> {
  _$CreateTodoListCopyWithImpl(this._self, this._then);

  final CreateTodoList _self;
  final $Res Function(CreateTodoList) _then;

/// Create a copy of CreateTodoList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? color = freezed,Object? personId = freezed,Object? reminderDateTime = freezed,Object? scheduledTime = freezed,Object? scheduledDays = freezed,Object? items = freezed,}) {
  return _then(CreateTodoList(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,personId: freezed == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String?,reminderDateTime: freezed == reminderDateTime ? _self.reminderDateTime : reminderDateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,scheduledTime: freezed == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as String?,scheduledDays: freezed == scheduledDays ? _self.scheduledDays : scheduledDays // ignore: cast_nullable_to_non_nullable
as String?,items: freezed == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CreateTodoItem>?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateTodoList].
extension CreateTodoListPatterns on CreateTodoList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateTodoList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateTodoList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateTodoList value)  $default,){
final _that = this;
switch (_that) {
case _CreateTodoList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateTodoList value)?  $default,){
final _that = this;
switch (_that) {
case _CreateTodoList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String? color,  String? personId, @WallClock()  DateTime? reminderDateTime,  String? scheduledTime,  String? scheduledDays,  List<CreateTodoItem>? items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateTodoList() when $default != null:
return $default(_that.title,_that.color,_that.personId,_that.reminderDateTime,_that.scheduledTime,_that.scheduledDays,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String? color,  String? personId, @WallClock()  DateTime? reminderDateTime,  String? scheduledTime,  String? scheduledDays,  List<CreateTodoItem>? items)  $default,) {final _that = this;
switch (_that) {
case _CreateTodoList():
return $default(_that.title,_that.color,_that.personId,_that.reminderDateTime,_that.scheduledTime,_that.scheduledDays,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String? color,  String? personId, @WallClock()  DateTime? reminderDateTime,  String? scheduledTime,  String? scheduledDays,  List<CreateTodoItem>? items)?  $default,) {final _that = this;
switch (_that) {
case _CreateTodoList() when $default != null:
return $default(_that.title,_that.color,_that.personId,_that.reminderDateTime,_that.scheduledTime,_that.scheduledDays,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateTodoList implements CreateTodoList {
  const _CreateTodoList({required this.title, this.color, this.personId, @WallClock() this.reminderDateTime, this.scheduledTime, this.scheduledDays,  List<CreateTodoItem>? items}): _items = items;
  factory _CreateTodoList.fromJson(Map<String, dynamic> json) => _$CreateTodoListFromJson(json);

@override final  String title;
@override final  String? color;
@override final  String? personId;
@override@WallClock() final  DateTime? reminderDateTime;
@override final  String? scheduledTime;
@override final  String? scheduledDays;
/// Optional seed items. Ungrouped, order preserved.
 final  List<CreateTodoItem>? _items;
/// Optional seed items. Ungrouped, order preserved.
@override List<CreateTodoItem>? get items {
  final value = _items;
  if (value == null) return null;
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of CreateTodoList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateTodoListCopyWith<_CreateTodoList> get copyWith => __$CreateTodoListCopyWithImpl<_CreateTodoList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateTodoListToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateTodoList&&(identical(other.title, title) || other.title == title)&&(identical(other.color, color) || other.color == color)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.reminderDateTime, reminderDateTime) || other.reminderDateTime == reminderDateTime)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.scheduledDays, scheduledDays) || other.scheduledDays == scheduledDays)&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,color,personId,reminderDateTime,scheduledTime,scheduledDays,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'CreateTodoList(title: $title, color: $color, personId: $personId, reminderDateTime: $reminderDateTime, scheduledTime: $scheduledTime, scheduledDays: $scheduledDays, items: $items)';
}


}

/// @nodoc
abstract mixin class _$CreateTodoListCopyWith<$Res> implements $CreateTodoListCopyWith<$Res> {
  factory _$CreateTodoListCopyWith(_CreateTodoList value, $Res Function(_CreateTodoList) _then) = __$CreateTodoListCopyWithImpl;
@override @useResult
$Res call({
 String title, String? color, String? personId,@WallClock() DateTime? reminderDateTime, String? scheduledTime, String? scheduledDays, List<CreateTodoItem>? items
});




}
/// @nodoc
class __$CreateTodoListCopyWithImpl<$Res>
    implements _$CreateTodoListCopyWith<$Res> {
  __$CreateTodoListCopyWithImpl(this._self, this._then);

  final _CreateTodoList _self;
  final $Res Function(_CreateTodoList) _then;

/// Create a copy of CreateTodoList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? color = freezed,Object? personId = freezed,Object? reminderDateTime = freezed,Object? scheduledTime = freezed,Object? scheduledDays = freezed,Object? items = freezed,}) {
  return _then(_CreateTodoList(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,personId: freezed == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String?,reminderDateTime: freezed == reminderDateTime ? _self.reminderDateTime : reminderDateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,scheduledTime: freezed == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as String?,scheduledDays: freezed == scheduledDays ? _self.scheduledDays : scheduledDays // ignore: cast_nullable_to_non_nullable
as String?,items: freezed == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CreateTodoItem>?,
  ));
}


}


/// @nodoc
mixin _$CreateTodoItem {

 String get content;@JsonKey(defaultValue: 0) int? get indentLevel; int? get groupId; String? get location;
/// Create a copy of CreateTodoItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateTodoItemCopyWith<CreateTodoItem> get copyWith => _$CreateTodoItemCopyWithImpl<CreateTodoItem>(this as CreateTodoItem, _$identity);

  /// Serializes this CreateTodoItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CreateTodoItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTodoItem&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.indentLevel, _this.indentLevel) || other.indentLevel == _this.indentLevel)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.location, _this.location) || other.location == _this.location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CreateTodoItem;
  return Object.hash(runtimeType,_this.content,_this.indentLevel,_this.groupId,_this.location);
}

@override
String toString() {
  final _this = this as CreateTodoItem;
  return 'CreateTodoItem(content: ${_this.content}, indentLevel: ${_this.indentLevel}, groupId: ${_this.groupId}, location: ${_this.location})';
}


}

/// @nodoc
abstract mixin class $CreateTodoItemCopyWith<$Res>  {
  factory $CreateTodoItemCopyWith(CreateTodoItem value, $Res Function(CreateTodoItem) _then) = _$CreateTodoItemCopyWithImpl;
@useResult
$Res call({
 String content,@JsonKey(defaultValue: 0) int? indentLevel, int? groupId, String? location
});




}
/// @nodoc
class _$CreateTodoItemCopyWithImpl<$Res>
    implements $CreateTodoItemCopyWith<$Res> {
  _$CreateTodoItemCopyWithImpl(this._self, this._then);

  final CreateTodoItem _self;
  final $Res Function(CreateTodoItem) _then;

/// Create a copy of CreateTodoItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? indentLevel = freezed,Object? groupId = freezed,Object? location = freezed,}) {
  return _then(CreateTodoItem(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,indentLevel: freezed == indentLevel ? _self.indentLevel : indentLevel // ignore: cast_nullable_to_non_nullable
as int?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateTodoItem].
extension CreateTodoItemPatterns on CreateTodoItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateTodoItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateTodoItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateTodoItem value)  $default,){
final _that = this;
switch (_that) {
case _CreateTodoItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateTodoItem value)?  $default,){
final _that = this;
switch (_that) {
case _CreateTodoItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String content, @JsonKey(defaultValue: 0)  int? indentLevel,  int? groupId,  String? location)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateTodoItem() when $default != null:
return $default(_that.content,_that.indentLevel,_that.groupId,_that.location);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String content, @JsonKey(defaultValue: 0)  int? indentLevel,  int? groupId,  String? location)  $default,) {final _that = this;
switch (_that) {
case _CreateTodoItem():
return $default(_that.content,_that.indentLevel,_that.groupId,_that.location);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String content, @JsonKey(defaultValue: 0)  int? indentLevel,  int? groupId,  String? location)?  $default,) {final _that = this;
switch (_that) {
case _CreateTodoItem() when $default != null:
return $default(_that.content,_that.indentLevel,_that.groupId,_that.location);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateTodoItem implements CreateTodoItem {
  const _CreateTodoItem({required this.content, @JsonKey(defaultValue: 0) this.indentLevel, this.groupId, this.location});
  factory _CreateTodoItem.fromJson(Map<String, dynamic> json) => _$CreateTodoItemFromJson(json);

@override final  String content;
@override@JsonKey(defaultValue: 0) final  int? indentLevel;
@override final  int? groupId;
@override final  String? location;

/// Create a copy of CreateTodoItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateTodoItemCopyWith<_CreateTodoItem> get copyWith => __$CreateTodoItemCopyWithImpl<_CreateTodoItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateTodoItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateTodoItem&&(identical(other.content, content) || other.content == content)&&(identical(other.indentLevel, indentLevel) || other.indentLevel == indentLevel)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.location, location) || other.location == location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,content,indentLevel,groupId,location);
}

@override
String toString() {
    return 'CreateTodoItem(content: $content, indentLevel: $indentLevel, groupId: $groupId, location: $location)';
}


}

/// @nodoc
abstract mixin class _$CreateTodoItemCopyWith<$Res> implements $CreateTodoItemCopyWith<$Res> {
  factory _$CreateTodoItemCopyWith(_CreateTodoItem value, $Res Function(_CreateTodoItem) _then) = __$CreateTodoItemCopyWithImpl;
@override @useResult
$Res call({
 String content,@JsonKey(defaultValue: 0) int? indentLevel, int? groupId, String? location
});




}
/// @nodoc
class __$CreateTodoItemCopyWithImpl<$Res>
    implements _$CreateTodoItemCopyWith<$Res> {
  __$CreateTodoItemCopyWithImpl(this._self, this._then);

  final _CreateTodoItem _self;
  final $Res Function(_CreateTodoItem) _then;

/// Create a copy of CreateTodoItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? indentLevel = freezed,Object? groupId = freezed,Object? location = freezed,}) {
  return _then(_CreateTodoItem(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,indentLevel: freezed == indentLevel ? _self.indentLevel : indentLevel // ignore: cast_nullable_to_non_nullable
as int?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
