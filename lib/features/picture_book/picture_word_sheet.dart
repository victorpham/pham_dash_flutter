import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../data/models/picture_book_models.dart';
import 'picture_word_image.dart';
import 'picture_book_providers.dart';

/// The upload endpoint's ceiling, the same one profile pictures are held to.
const int _maxImageBytes = 5 * 1024 * 1024;

/// Add a word to [bookId], or edit / delete [word] when given.
Future<void> showPictureWordSheet(
  BuildContext context, {
  required int bookId,
  PictureWord? word,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => PictureWordSheet(bookId: bookId, word: word),
  );
}

class PictureWordSheet extends ConsumerStatefulWidget {
  const PictureWordSheet({super.key, required this.bookId, this.word});

  final int bookId;
  final PictureWord? word;

  @override
  ConsumerState<PictureWordSheet> createState() => _PictureWordSheetState();
}

class _PictureWordSheetState extends ConsumerState<PictureWordSheet> {
  late final TextEditingController _text = TextEditingController(
    text: widget.word?.word,
  );

  XFile? _picked;
  bool _busy = false;

  bool get _isNew => widget.word == null;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    if (await picked.length() > _maxImageBytes) {
      _toast('That image is larger than 5 MB.');
      return;
    }
    setState(() => _picked = picked);
  }

  Future<void> _save() async {
    final text = _text.text.trim();
    if (text.isEmpty) {
      _toast('Type the word that goes with the picture.');
      return;
    }

    final repository = ref.read(pictureBookRepositoryProvider);
    final existing = widget.word;
    setState(() => _busy = true);

    // Two calls, word then picture. If the second fails the word still landed,
    // so the sheet closes and says so rather than offering a save that would
    // now 409 on the word it just created.
    PictureWord? saved;
    try {
      if (existing == null) {
        saved = await repository.createWord(widget.bookId, text);
      } else if (text != existing.word) {
        saved = await repository.updateWord(existing.id, text);
      } else {
        saved = existing;
      }

      final picked = _picked;
      if (picked != null) {
        await repository.setWordImage(
          saved.id,
          filePath: picked.path,
          fileName: picked.name,
        );
      }
      _close();
    } on ApiException catch (error) {
      if (saved == null) {
        // Includes the 409 for a word the book already has — the server's
        // sentence names it.
        _toast(error.message);
        if (mounted) setState(() => _busy = false);
      } else {
        // Toast first: the messenger belongs to the screen below, but this
        // context stops being usable once the sheet is popped.
        _toast(
          'Saved "$text", but the picture did not upload: ${error.message}',
        );
        _close();
      }
    }
  }

  /// Invalidates before popping: `ref` is unusable once the sheet is gone.
  void _close() {
    if (!mounted) return;
    invalidatePictureBook(ref, widget.bookId);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final word = widget.word!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${word.word}"?'),
        content: const Text('Its picture goes too. This cannot be undone.'),
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
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(pictureBookRepositoryProvider).deleteWord(word.id);
      _close();
    } on ApiException catch (error) {
      _toast(error.message);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final picked = _picked;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isNew ? 'New word' : 'Edit word',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: scheme.surfaceContainerHighest,
                  child: picked != null
                      ? Image.file(File(picked.path), fit: BoxFit.cover)
                      : PictureWordImage(
                          imageUrl: widget.word?.imageUrl,
                          word: _text.text,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('word-field'),
              controller: _text,
              enabled: !_busy,
              maxLength: 50,
              textCapitalization: TextCapitalization.none,
              style: theme.textTheme.headlineSmall,
              decoration: const InputDecoration(
                labelText: 'Word',
                hintText: 'dog',
                border: OutlineInputBorder(),
              ),
              // The placeholder card shows the word's first letter.
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!_isNew)
                  TextButton.icon(
                    key: const ValueKey('delete-word'),
                    onPressed: _busy ? null : _delete,
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                const Spacer(),
                FilledButton(
                  key: const ValueKey('save-word'),
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
