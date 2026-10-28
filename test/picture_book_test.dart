import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/api/api_exception.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/core/speech/speaker.dart';
import 'package:pham_dash_flutter/data/models/picture_book_models.dart';
import 'package:pham_dash_flutter/data/repositories/picture_book_repository.dart';
import 'package:pham_dash_flutter/features/picture_book/flashcards_screen.dart';
import 'package:pham_dash_flutter/features/picture_book/picture_book_screen.dart';

const _bookId = 1;

/// Words with no picture, so every tile and card draws its placeholder letter
/// and no `CachedNetworkImage` reaches for the network.
List<PictureWord> _words(List<String> words) => [
  for (var i = 0; i < words.length; i++)
    PictureWord(
      id: i + 10,
      pictureBookId: _bookId,
      word: words[i],
      displayOrder: i + 1,
    ),
];

/// An in-memory book. Subclasses rather than implements: the repository holds
/// a private `ApiClient`, which is never touched here.
class _FakeBooks extends PictureBookRepository {
  _FakeBooks(super.api, this.stored);

  List<PictureWord> stored;
  final created = <String>[];
  final deleted = <int>[];

  @override
  Future<List<PictureBook>> books() async => [
    PictureBook(id: _bookId, title: 'Animals', wordCount: stored.length),
  ];

  @override
  Future<List<PictureWord>> words(int bookId) async => stored;

  @override
  Future<PictureWord> createWord(int bookId, String word) async {
    final lowered = word.toLowerCase();
    if (stored.any((w) => w.word.toLowerCase() == lowered)) {
      throw ApiException(409, '"$word" is already in this book.');
    }
    created.add(word);
    final added = PictureWord(
      id: 100 + created.length,
      pictureBookId: bookId,
      word: word,
      displayOrder: stored.length + 1,
    );
    stored = [...stored, added];
    return added;
  }

  @override
  Future<void> deleteWord(int wordId) async {
    deleted.add(wordId);
    stored = stored.where((w) => w.id != wordId).toList();
  }
}

class _RecordingSpeaker extends Speaker {
  final spoken = <String>[];

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

Future<_FakeBooks> _pump(
  WidgetTester tester,
  Widget screen, {
  List<String> words = const ['dog', 'cat'],
  Speaker? speaker,
}) async {
  // A phone, not the default 800x600: the word sheet's picture preview would
  // otherwise push Save below the fold.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final books = _FakeBooks(ApiClient(AuthService()), _words(words));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pictureBookRepositoryProvider.overrideWithValue(books),
        cacheStorageProvider.overrideWithValue(Storage.inMemory()),
        if (speaker != null) speakerProvider.overrideWithValue(speaker),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
  return books;
}

void main() {
  test('a word round-trips through its wire shape', () {
    final word = PictureWord.fromJson({
      'id': 3,
      'pictureBookId': 1,
      'word': 'Mommy',
      'imageUrl': '/uploads/picture-book/3_x.jpg?exp=1&sig=abc',
      'displayOrder': 2,
      'createdAt': '2026-10-28T10:00:00',
    });

    expect(word.word, 'Mommy');
    // A UTC instant missing its Z, like every createdAt the API sends.
    expect(
      word.createdAt!.isAtSameMomentAs(DateTime.utc(2026, 10, 28, 10)),
      isTrue,
    );
    final again = PictureWord.fromJson(word.toJson());
    expect(again.copyWith(createdAt: null), word.copyWith(createdAt: null));
    expect(again.createdAt!.isAtSameMomentAs(word.createdAt!), isTrue);
  });

  group('the parent grid', () {
    testWidgets('shows every word with the book title', (tester) async {
      await _pump(tester, const PictureBookScreen(bookId: _bookId));

      expect(find.text('Animals'), findsOneWidget);
      expect(find.byKey(const ValueKey('word-10')), findsOneWidget);
      expect(find.byKey(const ValueKey('word-11')), findsOneWidget);
    });

    testWidgets('adding a word saves it and shows it in the grid', (
      tester,
    ) async {
      final books = await _pump(
        tester,
        const PictureBookScreen(bookId: _bookId),
      );

      await tester.tap(find.byKey(const ValueKey('add-word')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('word-field')),
        ' ball ',
      );
      await tester.tap(find.byKey(const ValueKey('save-word')));
      await tester.pumpAndSettle();

      expect(books.created, ['ball']);
      expect(find.byKey(const ValueKey('save-word')), findsNothing);
      expect(find.byKey(const ValueKey('word-101')), findsOneWidget);
    });

    testWidgets('a duplicate word keeps the sheet open and says why', (
      tester,
    ) async {
      final books = await _pump(
        tester,
        const PictureBookScreen(bookId: _bookId),
      );

      await tester.tap(find.byKey(const ValueKey('add-word')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('word-field')), 'Dog');
      await tester.tap(find.byKey(const ValueKey('save-word')));
      await tester.pumpAndSettle();

      expect(books.created, isEmpty);
      expect(find.text('"Dog" is already in this book.'), findsOneWidget);
      expect(find.byKey(const ValueKey('save-word')), findsOneWidget);
    });

    testWidgets('deleting a word asks first', (tester) async {
      final books = await _pump(
        tester,
        const PictureBookScreen(bookId: _bookId),
      );

      await tester.tap(find.byKey(const ValueKey('word-10')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-word')));
      await tester.pumpAndSettle();

      expect(find.text('Delete "dog"?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(books.deleted, [10]);
      expect(find.byKey(const ValueKey('word-10')), findsNothing);
    });
  });

  group('the flashcards', () {
    testWidgets('say the first word on opening and again on a tap', (
      tester,
    ) async {
      final speaker = _RecordingSpeaker();
      await _pump(
        tester,
        const FlashcardsScreen(bookId: _bookId),
        speaker: speaker,
      );

      expect(speaker.spoken, ['dog']);

      await tester.tap(find.byKey(const ValueKey('flashcard-10')));
      await tester.pump();
      expect(speaker.spoken, ['dog', 'dog']);
    });

    testWidgets('swiping to the next card says its word', (tester) async {
      final speaker = _RecordingSpeaker();
      await _pump(
        tester,
        const FlashcardsScreen(bookId: _bookId),
        speaker: speaker,
      );

      await tester.fling(
        find.byKey(const ValueKey('flashcard-10')),
        const Offset(-600, 0),
        1500,
      );
      await tester.pumpAndSettle();

      expect(speaker.spoken, ['dog', 'cat']);
      expect(find.text('cat'), findsOneWidget);
    });
  });
}
