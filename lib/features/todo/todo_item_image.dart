import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../data/models/todo_models.dart';

/// The upload endpoint's ceiling, the same one profile pictures are held to.
const int kMaxItemImageBytes = 5 * 1024 * 1024;

/// A list item's picture at row size. Renders nothing when the item has no
/// picture, or has one the server would not sign.
///
/// Like [PersonAvatar], this leans on the URL being signed already - a plain
/// GET with no bearer token is enough, and the signature rides in the query
/// string that [AppConfig.mediaUrl] keeps intact.
class TodoItemThumbnail extends StatelessWidget {
  const TodoItemThumbnail({super.key, required this.item, this.size = 48});

  final TodoItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.mediaUrl(item.imageUrl);
    if (url == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ClipRRect(
        key: ValueKey('item-image-${item.id}'),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => showTodoItemImage(context, item),
          child: CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
              width: size,
              height: size,
              color: scheme.surfaceContainerHighest,
            ),
            errorWidget: (_, _, _) => Container(
              width: size,
              height: size,
              color: scheme.surfaceContainerHighest,
              child: Icon(Icons.broken_image_outlined, color: scheme.outline),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the item's picture full-screen, pinch-zoomable. The point of the
/// feature is recognising a product on a shelf, and a 48px thumbnail is not
/// always enough for that.
Future<void> showTodoItemImage(BuildContext context, TodoItem item) {
  final url = AppConfig.mediaUrl(item.imageUrl);
  if (url == null) return Future.value();

  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => TodoItemImageViewer(title: item.content, url: url),
    ),
  );
}

class TodoItemImageViewer extends StatelessWidget {
  const TodoItemImageViewer({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      // A tap on the black surround closes the viewer; the close button in the
      // corner is a long reach one-handed in a shop aisle. The image itself
      // swallows taps so pinch-and-pan on it never dismisses by accident.
      body: GestureDetector(
        key: const ValueKey('item-image-backdrop'),
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: InteractiveViewer(
            maxScale: 5,
            child: GestureDetector(
              onTap: () {},
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, _) => const CircularProgressIndicator(),
                errorWidget: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
