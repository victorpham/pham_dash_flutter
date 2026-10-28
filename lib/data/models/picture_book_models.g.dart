// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'picture_book_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PictureBook _$PictureBookFromJson(Map<String, dynamic> json) => _PictureBook(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
  wordCount: (json['wordCount'] as num?)?.toInt() ?? 0,
  coverImageUrl: json['coverImageUrl'] as String?,
  createdAt: const UtcStamp().fromJson(json['createdAt'] as String?),
  updatedAt: const UtcStamp().fromJson(json['updatedAt'] as String?),
);

Map<String, dynamic> _$PictureBookToJson(_PictureBook instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'displayOrder': instance.displayOrder,
      'wordCount': instance.wordCount,
      'coverImageUrl': instance.coverImageUrl,
      'createdAt': const UtcStamp().toJson(instance.createdAt),
      'updatedAt': const UtcStamp().toJson(instance.updatedAt),
    };

_PictureWord _$PictureWordFromJson(Map<String, dynamic> json) => _PictureWord(
  id: (json['id'] as num).toInt(),
  pictureBookId: (json['pictureBookId'] as num).toInt(),
  word: json['word'] as String,
  imageUrl: json['imageUrl'] as String?,
  displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
  createdAt: const UtcStamp().fromJson(json['createdAt'] as String?),
  updatedAt: const UtcStamp().fromJson(json['updatedAt'] as String?),
);

Map<String, dynamic> _$PictureWordToJson(_PictureWord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pictureBookId': instance.pictureBookId,
      'word': instance.word,
      'imageUrl': instance.imageUrl,
      'displayOrder': instance.displayOrder,
      'createdAt': const UtcStamp().toJson(instance.createdAt),
      'updatedAt': const UtcStamp().toJson(instance.updatedAt),
    };
