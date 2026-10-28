import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/speech/speaker.dart';
import '../../core/ui/async_view.dart';
import '../../data/models/picture_book_models.dart';
import 'picture_book_providers.dart';
import 'picture_word_image.dart';

/// The toddler's view of a book: one big picture and one big word per page.
///
/// Swiping to a card says its word once; tapping anywhere on the card says it
/// again. Full-screen with nothing to edit and a single small close button, so
/// the phone can be handed over without a parent's controls in reach.
class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key, required this.bookId});

  final int bookId;

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  final PageController _pages = PageController();
  int _index = 0;

  /// Whether the first card has been spoken. `onPageChanged` does not fire
  /// for the page a `PageView` opens on.
  bool _spokeFirst = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pages.dispose();
    super.dispose();
  }

  void _speak(PictureWord word) => ref.read(speakerProvider).speak(word.word);

  void _go(int delta) => _pages.animateToPage(
    _index + delta,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final words = ref.watch(pictureWordsProvider(widget.bookId));

    // Always light, whatever the app's dark mode says: black on white is the
    // point of the card, and the loading / error states have to read on it.
    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: AsyncView<List<PictureWord>>(
            value: words,
            onRetry: () => ref.invalidate(pictureWordsProvider(widget.bookId)),
            emptyTitle: 'No words in this book yet',
            emptyIcon: Icons.auto_stories_outlined,
            builder: (list) {
              if (!_spokeFirst) {
                _spokeFirst = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _speak(list[_index.clamp(0, list.length - 1)]);
                });
              }
              return Stack(
                children: [
                  PageView.builder(
                    controller: _pages,
                    itemCount: list.length,
                    onPageChanged: (index) {
                      setState(() => _index = index);
                      _speak(list[index]);
                    },
                    itemBuilder: (context, index) => _Flashcard(
                      word: list[index],
                      onTap: () => _speak(list[index]),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      key: const ValueKey('close-flashcards'),
                      tooltip: 'Close',
                      color: Colors.black45,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  if (_index > 0)
                    _Arrow(
                      alignment: Alignment.centerLeft,
                      icon: Icons.chevron_left,
                      onPressed: () => _go(-1),
                    ),
                  if (_index < list.length - 1)
                    _Arrow(
                      alignment: Alignment.centerRight,
                      icon: Icons.chevron_right,
                      onPressed: () => _go(1),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Flashcard extends StatelessWidget {
  const _Flashcard({required this.word, required this.onTap});

  final PictureWord word;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('flashcard-${word.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(56, 48, 56, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: PictureWordImage(
                  imageUrl: word.imageUrl,
                  word: word.word,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Black on white, heavy, and as large as fits: an early reader
            // matches letter shapes, so contrast beats styling.
            SizedBox(
              height: 120,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  word.word,
                  style: const TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.alignment,
    required this.icon,
    required this.onPressed,
  });

  final Alignment alignment;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IconButton(
        iconSize: 48,
        color: Colors.black26,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
