import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/app_config.dart';
import '../../core/providers.dart';
import '../../core/ui/async_view.dart';
import '../../data/models/picture_book_models.dart';
import 'picture_book_providers.dart';

/// Every picture book, as a grid of covers. The parent's way in: open a book
/// to manage its words or start the flashcards.
class PictureBooksScreen extends ConsumerWidget {
  const PictureBooksScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final title = await promptForBookTitle(context);
    if (title == null || !context.mounted) return;

    try {
      final book = await ref
          .read(pictureBookRepositoryProvider)
          .createBook(title);
      ref.invalidate(pictureBooksProvider);
      if (context.mounted) context.push('/picture-book/${book.id}');
    } on ApiException catch (error) {
      if (context.mounted) _toast(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(pictureBooksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Picture Book')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New book'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(pictureBooksProvider.future),
        child: AsyncView<List<PictureBook>>(
          value: books,
          onRetry: () => ref.invalidate(pictureBooksProvider),
          emptyTitle: 'No books yet',
          emptyMessage: 'Make a book like "Animals" or "Food", then add a picture for each word.',
          emptyIcon: Icons.auto_stories_outlined,
          builder: (list) => GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.82,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) => _BookCard(book: list[index]),
          ),
        ),
      ),
    );
  }
}

class _BookCard extends ConsumerWidget {
  const _BookCard({required this.book});

  final PictureBook book;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final title = await promptForBookTitle(context, initial: book.title);
    if (title == null || title == book.title || !context.mounted) return;
    try {
      await ref.read(pictureBookRepositoryProvider).renameBook(book.id, title);
      ref.invalidate(pictureBooksProvider);
    } on ApiException catch (error) {
      if (context.mounted) _toast(context, error.message);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${book.title}"?'),
        content: Text(
          book.wordCount == 0
              ? 'This cannot be undone.'
              : 'Its ${book.wordCount} '
                    '${book.wordCount == 1 ? 'word goes' : 'words go'} too, '
                    'pictures and all. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(pictureBookRepositoryProvider).deleteBook(book.id);
      ref.invalidate(pictureBooksProvider);
    } on ApiException catch (error) {
      if (context.mounted) _toast(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cover = AppConfig.mediaUrl(book.coverImageUrl);

    return Card(
      key: ValueKey('book-${book.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/picture-book/${book.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: scheme.surfaceContainerHighest,
                child: cover == null
                    ? Icon(
                        Icons.auto_stories_outlined,
                        size: 48,
                        color: scheme.outline,
                      )
                    : CachedNetworkImage(
                        imageUrl: cover,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Icon(
                          Icons.auto_stories_outlined,
                          size: 48,
                          color: scheme.outline,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 0, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${book.wordCount} '
                          '${book.wordCount == 1 ? 'word' : 'words'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    key: ValueKey('book-menu-${book.id}'),
                    onSelected: (choice) => choice == 'rename'
                        ? _rename(context, ref)
                        : _delete(context, ref),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for a book title. Null when cancelled or left blank.
Future<String?> promptForBookTitle(BuildContext context, {String? initial}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TitleDialog(initial: initial),
  );
}

class _TitleDialog extends StatefulWidget {
  const _TitleDialog({this.initial});

  final String? initial;

  @override
  State<_TitleDialog> createState() => _TitleDialogState();
}

class _TitleDialogState extends State<_TitleDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    Navigator.pop(context, title.isEmpty ? null : title);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'New book' : 'Rename book'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 100,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'Animals',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

void _toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
