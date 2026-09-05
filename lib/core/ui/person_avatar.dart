import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// A person's profile picture, falling back to their initials.
///
/// Profile pictures are static files served from the API origin, ahead of the
/// authentication middleware, so they need no bearer token — a plain image GET
/// is enough. [AppConfig.mediaUrl] handles both the normal root-relative path
/// and the legacy rows that stored a full absolute URL against an old host.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.storedPath,
    required this.initials,
    this.size = 48,
  });

  final String? storedPath;
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = AppConfig.mediaUrl(storedPath);

    final placeholder = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.36,
        ),
      ),
    );

    if (url == null) return placeholder;

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}
