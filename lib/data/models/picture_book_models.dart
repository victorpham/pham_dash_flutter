import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';

part 'picture_book_models.freezed.dart';
part 'picture_book_models.g.dart';

/// A toddler's first-words book — `GET /api/picture-books`.
///
/// Family-wide like `Person`: no `UserId`, every signed-in parent sees the same
/// books. [wordCount] and [coverImageUrl] are computed server-side from the
/// words, so a word write has to invalidate the book list too.
@freezed
abstract class PictureBook with _$PictureBook {
  const factory PictureBook({
    required int id,
    required String title,
    @Default(0) int displayOrder,
    @Default(0) int wordCount,

    /// The first word (by order) that has a picture. Signed and root-relative;
    /// resolve with `AppConfig.mediaUrl`, which keeps the signature intact.
    String? coverImageUrl,
    @UtcStamp() DateTime? createdAt,
    @UtcStamp() DateTime? updatedAt,
  }) = _PictureBook;

  factory PictureBook.fromJson(Map<String, dynamic> json) =>
      _$PictureBookFromJson(json);
}

/// One flashcard: a picture and the word it shows. The word is stored as
/// typed, so "Mommy" and "dog" both read right on the card.
@freezed
abstract class PictureWord with _$PictureWord {
  const factory PictureWord({
    required int id,
    required int pictureBookId,
    required String word,

    /// Signed and root-relative, or null before a picture is added.
    String? imageUrl,
    @Default(0) int displayOrder,
    @UtcStamp() DateTime? createdAt,
    @UtcStamp() DateTime? updatedAt,
  }) = _PictureWord;

  factory PictureWord.fromJson(Map<String, dynamic> json) =>
      _$PictureWordFromJson(json);
}
