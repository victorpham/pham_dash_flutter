import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

/// A word's picture, or — with none, or one the server would not sign — the
/// word's first letter, big, so a card still has something to look at.
class PictureWordImage extends StatelessWidget {
  const PictureWordImage({
    super.key,
    required this.imageUrl,
    required this.word,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final String word;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.mediaUrl(imageUrl);
    if (url == null) return _Initial(word: word);

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, _) => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, _, _) => _Initial(word: word),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trimmed = word.trim();
    if (trimmed.isEmpty) {
      return Center(
        child: Icon(Icons.image_outlined, size: 48, color: scheme.outline),
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          trimmed.characters.first.toUpperCase(),
          style: TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.w800,
            color: scheme.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
