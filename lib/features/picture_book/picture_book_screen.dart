import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/ui/async_view.dart';
import '../../data/models/picture_book_models.dart';
import 'picture_book_providers.dart';
import 'picture_word_image.dart';
import 'picture_word_sheet.dart';

/// One book, for the parent: a grid of its words to add, edit and delete, a
/// reorder mode, and Play to hand the phone to the toddler.
class PictureBookScreen extends ConsumerStatefulWidget {
  const PictureBookScreen({super.key, required this.bookId});

  final int bookId;

  @override
  ConsumerState<PictureBookScreen> createState() => _PictureBookScreenState();
}

class _PictureBookScreenState extends ConsumerState<PictureBookScreen> {
  bool _reordering = false;

  /// The order just dragged into place, shown until the refetch confirms it —
  /// otherwise the row snaps back for the length of a round trip.
  List<PictureWord>? _pendingOrder;

  int get _bookId => widget.bookId;

  Future<void> _reorder(List<PictureWord> words, int from, int to) async {
    final reordered = [...words];
    final moved = reordered.removeAt(from);
    // `onReorderItem` hands over [to] already adjusted for the removal.
    reordered.insert(to, moved);
    setState(() => _pendingOrder = reordered);

    try {
      await ref.read(pictureBookRepositoryProvider).reorderWords(_bookId, [
        for (final word in reordered) word.id,
      ]);
      invalidatePictureBook(ref, _bookId);
      await ref.read(pictureWordsProvider(_bookId).future);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _pendingOrder = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = ref.watch(pictureWordsProvider(_bookId));
    final title = pictureBookById(ref, _bookId)?.title ?? 'Picture book';
    final hasWords = (words.value ?? const []).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: _reordering ? 'Done reordering' : 'Reorder',
            onPressed: hasWords
                ? () => setState(() => _reordering = !_reordering)
                : null,
            icon: Icon(_reordering ? Icons.check : Icons.swap_vert),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              key: const ValueKey('play'),
              onPressed: hasWords
                  ? () => context.push('/picture-book/$_bookId/play')
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
            ),
          ),
        ],
      ),
      floatingActionButton: _reordering
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey('add-word'),
              onPressed: () => showPictureWordSheet(context, bookId: _bookId),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add word'),
            ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(pictureWordsProvider(_bookId).future),
        child: AsyncView<List<PictureWord>>(
          value: words,
          onRetry: () => ref.invalidate(pictureWordsProvider(_bookId)),
          emptyTitle: 'No words yet',
          emptyMessage: 'Take a picture of something and type its word — "dog", "ball", "Mommy".',
          emptyIcon: Icons.add_a_photo_outlined,
          builder: (list) {
            final shown = _pendingOrder ?? list;
            return _reordering
                ? _ReorderList(
                    words: shown,
                    onReorder: (from, to) => _reorder(shown, from, to),
                  )
                : _WordGrid(
                    words: shown,
                    onTap: (word) => showPictureWordSheet(
                      context,
                      bookId: _bookId,
                      word: word,
                    ),
                  );
          },
        ),
      ),
    );
  }
}

class _WordGrid extends StatelessWidget {
  const _WordGrid({required this.words, required this.onTap});

  final List<PictureWord> words;
  final void Function(PictureWord) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return Card(
          key: ValueKey('word-${word.id}'),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onTap(word),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: PictureWordImage(
                      imageUrl: word.imageUrl,
                      word: word.word,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  child: Text(
                    word.word,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReorderList extends StatelessWidget {
  const _ReorderList({required this.words, required this.onReorder});

  final List<PictureWord> words;
  final void Function(int from, int to) onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: words.length,
      onReorderItem: onReorder,
      itemBuilder: (context, index) {
        final word = words[index];
        return ListTile(
          key: ValueKey('reorder-${word.id}'),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox.square(
              dimension: 48,
              child: PictureWordImage(imageUrl: word.imageUrl, word: word.word),
            ),
          ),
          title: Text(word.word),
          trailing: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
        );
      },
    );
  }
}
