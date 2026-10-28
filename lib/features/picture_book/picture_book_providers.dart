import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cached_list.dart';
import '../../core/providers.dart';
import '../../data/models/picture_book_models.dart';

/// Every picture book, in display order.
///
/// Cached and kept alive like the directory lists: the flashcards are as
/// likely to be opened on a sofa with no signal, or while the database naps,
/// as anywhere else. The cached URLs are signed for two days, so an older copy
/// shows placeholder covers until the fresh list lands — the same caveat as
/// `personPicturesProvider`.
final pictureBooksProvider =
    AsyncNotifierProvider<PictureBooksNotifier, List<PictureBook>>(
      PictureBooksNotifier.new,
    );

class PictureBooksNotifier extends AsyncNotifier<List<PictureBook>>
    with CachedList<PictureBook> {
  @override
  Future<List<PictureBook>> build() {
    persistList(
      'picture_books',
      fromJson: PictureBook.fromJson,
      toJson: (book) => book.toJson(),
    );
    return ref.watch(pictureBookRepositoryProvider).books();
  }
}

/// One book's words, in display order — what both the parent grid and the
/// flashcards read. Cached per book, like a person's gallery.
final pictureWordsProvider = AsyncNotifierProvider.autoDispose
    .family<PictureWordsNotifier, List<PictureWord>, int>(
      PictureWordsNotifier.new,
    );

class PictureWordsNotifier extends AsyncNotifier<List<PictureWord>>
    with CachedList<PictureWord> {
  PictureWordsNotifier(this.bookId);

  final int bookId;

  @override
  Future<List<PictureWord>> build() {
    persistList(
      'picture_book:$bookId',
      fromJson: PictureWord.fromJson,
      toJson: (word) => word.toJson(),
    );
    return ref.watch(pictureBookRepositoryProvider).words(bookId);
  }
}

/// After any write to [bookId]'s words. The book list goes too: its word count
/// and cover are derived from the words server-side.
void invalidatePictureBook(WidgetRef ref, int bookId) {
  ref.invalidate(pictureWordsProvider(bookId));
  ref.invalidate(pictureBooksProvider);
}

/// The cached row for [bookId], for a title while its words load.
PictureBook? pictureBookById(WidgetRef ref, int bookId) {
  for (final book in ref.watch(pictureBooksProvider).value ?? const []) {
    if (book.id == bookId) return book;
  }
  return null;
}
