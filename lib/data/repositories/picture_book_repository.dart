import '../../core/api/api_client.dart';
import '../models/picture_book_models.dart';
import 'decode.dart';

/// Picture books and their words — `/api/picture-books`.
///
/// Creating a word and giving it a picture are two calls on the server, so a
/// caller that has both does [createWord] and then [setWordImage].
class PictureBookRepository {
  const PictureBookRepository(this._api);

  final ApiClient _api;

  /// In display order.
  Future<List<PictureBook>> books() async => decodeList(
    await _api.get<dynamic>('/picture-books'),
    PictureBook.fromJson,
  );

  /// A book's words, in display order. Read off the detail payload; the book
  /// fields beside them are already in [books].
  Future<List<PictureWord>> words(int bookId) async {
    final data = await _api.get<dynamic>('/picture-books/$bookId');
    return decodeList(data is Map ? data['words'] : null, PictureWord.fromJson);
  }

  Future<PictureBook> createBook(String title) async => decodeRequired(
    await _api.post<dynamic>('/picture-books', body: {'title': title}),
    PictureBook.fromJson,
    'the created book',
  );

  Future<PictureBook> renameBook(int bookId, String title) async =>
      decodeRequired(
        await _api.put<dynamic>(
          '/picture-books/$bookId',
          body: {'title': title},
        ),
        PictureBook.fromJson,
        'the renamed book',
      );

  /// Takes the book's words and their pictures with it.
  Future<void> deleteBook(int bookId) => _api.delete('/picture-books/$bookId');

  /// 409s when the book already has the word (ignoring case); the message is
  /// worth showing as-is.
  Future<PictureWord> createWord(int bookId, String word) async =>
      decodeRequired(
        await _api.post<dynamic>(
          '/picture-books/$bookId/words',
          body: {'word': word},
        ),
        PictureWord.fromJson,
        'the created word',
      );

  /// 409s like [createWord] when renamed onto another word in the book.
  Future<PictureWord> updateWord(int wordId, String word) async =>
      decodeRequired(
        await _api.put<dynamic>(
          '/picture-books/words/$wordId',
          body: {'word': word},
        ),
        PictureWord.fromJson,
        'the updated word',
      );

  Future<void> deleteWord(int wordId) =>
      _api.delete('/picture-books/words/$wordId');

  /// Replaces any picture the word already has.
  Future<PictureWord> setWordImage(
    int wordId, {
    required String filePath,
    required String fileName,
  }) async => decodeRequired(
    await _api.upload<dynamic>(
      '/picture-books/words/$wordId/image',
      filePath: filePath,
      fileName: fileName,
    ),
    PictureWord.fromJson,
    'the word with its picture',
  );

  /// The full order; ids not in the book are skipped server-side.
  Future<void> reorderWords(int bookId, List<int> wordIds) =>
      _api.post<dynamic>(
        '/picture-books/$bookId/words/reorder',
        body: {'ids': wordIds},
      );
}
