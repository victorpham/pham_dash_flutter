// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'picture_book_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PictureBook {

 int get id; String get title; int get displayOrder; int get wordCount;/// The first word (by order) that has a picture. Signed and root-relative;
/// resolve with `AppConfig.mediaUrl`, which keeps the signature intact.
 String? get coverImageUrl;@UtcStamp() DateTime? get createdAt;@UtcStamp() DateTime? get updatedAt;
/// Create a copy of PictureBook
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PictureBookCopyWith<PictureBook> get copyWith => _$PictureBookCopyWithImpl<PictureBook>(this as PictureBook, _$identity);

  /// Serializes this PictureBook to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PictureBook;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PictureBook&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.displayOrder, _this.displayOrder) || other.displayOrder == _this.displayOrder)&&(identical(other.wordCount, _this.wordCount) || other.wordCount == _this.wordCount)&&(identical(other.coverImageUrl, _this.coverImageUrl) || other.coverImageUrl == _this.coverImageUrl)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PictureBook;
  return Object.hash(runtimeType,_this.id,_this.title,_this.displayOrder,_this.wordCount,_this.coverImageUrl,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as PictureBook;
  return 'PictureBook(id: ${_this.id}, title: ${_this.title}, displayOrder: ${_this.displayOrder}, wordCount: ${_this.wordCount}, coverImageUrl: ${_this.coverImageUrl}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $PictureBookCopyWith<$Res>  {
  factory $PictureBookCopyWith(PictureBook value, $Res Function(PictureBook) _then) = _$PictureBookCopyWithImpl;
@useResult
$Res call({
 int id, String title, int displayOrder, int wordCount, String? coverImageUrl,@UtcStamp() DateTime? createdAt,@UtcStamp() DateTime? updatedAt
});




}
/// @nodoc
class _$PictureBookCopyWithImpl<$Res>
    implements $PictureBookCopyWith<$Res> {
  _$PictureBookCopyWithImpl(this._self, this._then);

  final PictureBook _self;
  final $Res Function(PictureBook) _then;

/// Create a copy of PictureBook
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? displayOrder = null,Object? wordCount = null,Object? coverImageUrl = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(PictureBook(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,wordCount: null == wordCount ? _self.wordCount : wordCount // ignore: cast_nullable_to_non_nullable
as int,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PictureBook].
extension PictureBookPatterns on PictureBook {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PictureBook value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PictureBook() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PictureBook value)  $default,){
final _that = this;
switch (_that) {
case _PictureBook():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PictureBook value)?  $default,){
final _that = this;
switch (_that) {
case _PictureBook() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  int displayOrder,  int wordCount,  String? coverImageUrl, @UtcStamp()  DateTime? createdAt, @UtcStamp()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PictureBook() when $default != null:
return $default(_that.id,_that.title,_that.displayOrder,_that.wordCount,_that.coverImageUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  int displayOrder,  int wordCount,  String? coverImageUrl, @UtcStamp()  DateTime? createdAt, @UtcStamp()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PictureBook():
return $default(_that.id,_that.title,_that.displayOrder,_that.wordCount,_that.coverImageUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  int displayOrder,  int wordCount,  String? coverImageUrl, @UtcStamp()  DateTime? createdAt, @UtcStamp()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PictureBook() when $default != null:
return $default(_that.id,_that.title,_that.displayOrder,_that.wordCount,_that.coverImageUrl,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PictureBook implements PictureBook {
  const _PictureBook({required this.id, required this.title, this.displayOrder = 0, this.wordCount = 0, this.coverImageUrl, @UtcStamp() this.createdAt, @UtcStamp() this.updatedAt});
  factory _PictureBook.fromJson(Map<String, dynamic> json) => _$PictureBookFromJson(json);

@override final  int id;
@override final  String title;
@override@JsonKey() final  int displayOrder;
@override@JsonKey() final  int wordCount;
/// The first word (by order) that has a picture. Signed and root-relative;
/// resolve with `AppConfig.mediaUrl`, which keeps the signature intact.
@override final  String? coverImageUrl;
@override@UtcStamp() final  DateTime? createdAt;
@override@UtcStamp() final  DateTime? updatedAt;

/// Create a copy of PictureBook
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PictureBookCopyWith<_PictureBook> get copyWith => __$PictureBookCopyWithImpl<_PictureBook>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PictureBookToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PictureBook&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&(identical(other.wordCount, wordCount) || other.wordCount == wordCount)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,displayOrder,wordCount,coverImageUrl,createdAt,updatedAt);
}

@override
String toString() {
    return 'PictureBook(id: $id, title: $title, displayOrder: $displayOrder, wordCount: $wordCount, coverImageUrl: $coverImageUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PictureBookCopyWith<$Res> implements $PictureBookCopyWith<$Res> {
  factory _$PictureBookCopyWith(_PictureBook value, $Res Function(_PictureBook) _then) = __$PictureBookCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, int displayOrder, int wordCount, String? coverImageUrl,@UtcStamp() DateTime? createdAt,@UtcStamp() DateTime? updatedAt
});




}
/// @nodoc
class __$PictureBookCopyWithImpl<$Res>
    implements _$PictureBookCopyWith<$Res> {
  __$PictureBookCopyWithImpl(this._self, this._then);

  final _PictureBook _self;
  final $Res Function(_PictureBook) _then;

/// Create a copy of PictureBook
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? displayOrder = null,Object? wordCount = null,Object? coverImageUrl = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_PictureBook(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,wordCount: null == wordCount ? _self.wordCount : wordCount // ignore: cast_nullable_to_non_nullable
as int,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$PictureWord {

 int get id; int get pictureBookId; String get word;/// Signed and root-relative, or null before a picture is added.
 String? get imageUrl; int get displayOrder;@UtcStamp() DateTime? get createdAt;@UtcStamp() DateTime? get updatedAt;
/// Create a copy of PictureWord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PictureWordCopyWith<PictureWord> get copyWith => _$PictureWordCopyWithImpl<PictureWord>(this as PictureWord, _$identity);

  /// Serializes this PictureWord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PictureWord;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PictureWord&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.pictureBookId, _this.pictureBookId) || other.pictureBookId == _this.pictureBookId)&&(identical(other.word, _this.word) || other.word == _this.word)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&(identical(other.displayOrder, _this.displayOrder) || other.displayOrder == _this.displayOrder)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PictureWord;
  return Object.hash(runtimeType,_this.id,_this.pictureBookId,_this.word,_this.imageUrl,_this.displayOrder,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as PictureWord;
  return 'PictureWord(id: ${_this.id}, pictureBookId: ${_this.pictureBookId}, word: ${_this.word}, imageUrl: ${_this.imageUrl}, displayOrder: ${_this.displayOrder}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $PictureWordCopyWith<$Res>  {
  factory $PictureWordCopyWith(PictureWord value, $Res Function(PictureWord) _then) = _$PictureWordCopyWithImpl;
@useResult
$Res call({
 int id, int pictureBookId, String word, String? imageUrl, int displayOrder,@UtcStamp() DateTime? createdAt,@UtcStamp() DateTime? updatedAt
});




}
/// @nodoc
class _$PictureWordCopyWithImpl<$Res>
    implements $PictureWordCopyWith<$Res> {
  _$PictureWordCopyWithImpl(this._self, this._then);

  final PictureWord _self;
  final $Res Function(PictureWord) _then;

/// Create a copy of PictureWord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pictureBookId = null,Object? word = null,Object? imageUrl = freezed,Object? displayOrder = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(PictureWord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,pictureBookId: null == pictureBookId ? _self.pictureBookId : pictureBookId // ignore: cast_nullable_to_non_nullable
as int,word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PictureWord].
extension PictureWordPatterns on PictureWord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PictureWord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PictureWord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PictureWord value)  $default,){
final _that = this;
switch (_that) {
case _PictureWord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PictureWord value)?  $default,){
final _that = this;
switch (_that) {
case _PictureWord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int pictureBookId,  String word,  String? imageUrl,  int displayOrder, @UtcStamp()  DateTime? createdAt, @UtcStamp()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PictureWord() when $default != null:
return $default(_that.id,_that.pictureBookId,_that.word,_that.imageUrl,_that.displayOrder,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int pictureBookId,  String word,  String? imageUrl,  int displayOrder, @UtcStamp()  DateTime? createdAt, @UtcStamp()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PictureWord():
return $default(_that.id,_that.pictureBookId,_that.word,_that.imageUrl,_that.displayOrder,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int pictureBookId,  String word,  String? imageUrl,  int displayOrder, @UtcStamp()  DateTime? createdAt, @UtcStamp()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PictureWord() when $default != null:
return $default(_that.id,_that.pictureBookId,_that.word,_that.imageUrl,_that.displayOrder,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PictureWord implements PictureWord {
  const _PictureWord({required this.id, required this.pictureBookId, required this.word, this.imageUrl, this.displayOrder = 0, @UtcStamp() this.createdAt, @UtcStamp() this.updatedAt});
  factory _PictureWord.fromJson(Map<String, dynamic> json) => _$PictureWordFromJson(json);

@override final  int id;
@override final  int pictureBookId;
@override final  String word;
/// Signed and root-relative, or null before a picture is added.
@override final  String? imageUrl;
@override@JsonKey() final  int displayOrder;
@override@UtcStamp() final  DateTime? createdAt;
@override@UtcStamp() final  DateTime? updatedAt;

/// Create a copy of PictureWord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PictureWordCopyWith<_PictureWord> get copyWith => __$PictureWordCopyWithImpl<_PictureWord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PictureWordToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PictureWord&&(identical(other.id, id) || other.id == id)&&(identical(other.pictureBookId, pictureBookId) || other.pictureBookId == pictureBookId)&&(identical(other.word, word) || other.word == word)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,pictureBookId,word,imageUrl,displayOrder,createdAt,updatedAt);
}

@override
String toString() {
    return 'PictureWord(id: $id, pictureBookId: $pictureBookId, word: $word, imageUrl: $imageUrl, displayOrder: $displayOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PictureWordCopyWith<$Res> implements $PictureWordCopyWith<$Res> {
  factory _$PictureWordCopyWith(_PictureWord value, $Res Function(_PictureWord) _then) = __$PictureWordCopyWithImpl;
@override @useResult
$Res call({
 int id, int pictureBookId, String word, String? imageUrl, int displayOrder,@UtcStamp() DateTime? createdAt,@UtcStamp() DateTime? updatedAt
});




}
/// @nodoc
class __$PictureWordCopyWithImpl<$Res>
    implements _$PictureWordCopyWith<$Res> {
  __$PictureWordCopyWithImpl(this._self, this._then);

  final _PictureWord _self;
  final $Res Function(_PictureWord) _then;

/// Create a copy of PictureWord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pictureBookId = null,Object? word = null,Object? imageUrl = freezed,Object? displayOrder = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_PictureWord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,pictureBookId: null == pictureBookId ? _self.pictureBookId : pictureBookId // ignore: cast_nullable_to_non_nullable
as int,word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
