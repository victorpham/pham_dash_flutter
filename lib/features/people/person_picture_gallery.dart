import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/app_config.dart';
import '../../core/providers.dart';
import '../../core/ui/async_view.dart';
import '../../data/models/people_models.dart';
import '../../data/repositories/people_repository.dart';
import 'people_providers.dart';

/// The upload endpoint's ceiling, same as the edit sheet checks.
const int _maxPictureBytes = 5 * 1024 * 1024;

/// Manage a person's pictures: add, choose which one is displayed, delete.
///
/// The chosen picture is what every avatar in the app renders — the people list,
/// birthdays, note authors, calendar attendees — because the server mirrors it
/// onto the person themselves. So each change here invalidates the whole person,
/// not just this sheet.
Future<void> showPersonPictureGallery(
  BuildContext context, {
  required Person person,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => PersonPictureGallery(person: person),
  );
}

class PersonPictureGallery extends ConsumerStatefulWidget {
  const PersonPictureGallery({super.key, required this.person});

  final Person person;

  @override
  ConsumerState<PersonPictureGallery> createState() =>
      _PersonPictureGalleryState();
}

class _PersonPictureGalleryState extends ConsumerState<PersonPictureGallery> {
  /// Blocks a second tap while a write is in flight. One flag for the whole
  /// sheet rather than per tile: these all reorder the same list, and letting
  /// two overlap is how the gallery and the displayed picture drift apart.
  bool _busy = false;

  String get _personId => widget.person.id;

  PeopleRepository get _repository => ref.read(peopleRepositoryProvider);

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Runs a write, then re-reads the person everywhere. Returns false if it
  /// failed, having already said so.
  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) invalidatePerson(ref, _personId);
      return true;
    } on ApiException catch (error) {
      // Includes the 409 from racing past the cap — the server's sentence is
      // more useful than anything invented here.
      _toast(error.message);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    if (await picked.length() > _maxPictureBytes) {
      _toast('That image is larger than 5 MB.');
      return;
    }

    await _run(() async {
      await _repository.addPicture(
        _personId,
        filePath: picked.path,
        fileName: picked.name,
      );
    });
  }

  Future<void> _setPrimary(PersonPicture picture) async {
    if (picture.isPrimary) return;
    await _run(() => _repository.setPrimaryPicture(_personId, picture.id));
  }

  Future<void> _delete(PersonPicture picture) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this picture?'),
        content: Text(
          picture.isPrimary
              ? 'It is the picture shown for ${widget.person.fullName}. '
                  'Their most recent remaining picture will take over.'
              : 'This cannot be undone.',
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

    if (confirmed != true) return;
    await _run(() => _repository.deletePicture(_personId, picture.id));
  }

  @override
  Widget build(BuildContext context) {
    final pictures = ref.watch(personPicturesProvider(_personId));
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pictures',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a picture to show it for ${widget.person.fullName}.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: AsyncView<List<PersonPicture>>(
              value: pictures,
              onRetry: () => ref.invalidate(personPicturesProvider(_personId)),
              emptyTitle: 'No pictures yet',
              emptyMessage: 'Add one and it becomes their profile picture.',
              emptyIcon: Icons.photo_library_outlined,
              builder: (list) => GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: list.length,
                itemBuilder: (context, index) => _PictureTile(
                  picture: list[index],
                  enabled: !_busy,
                  onTap: () => _setPrimary(list[index]),
                  onDelete: () => _delete(list[index]),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          // Hidden at the cap rather than letting the upload fail: the picker is
          // several taps, and losing them to a 409 at the end is worse than not
          // offering it. A racing second device still gets the message.
          if ((pictures.asData?.value.length ?? 0) < maxPicturesPerPerson)
            FilledButton.icon(
              onPressed: _busy ? null : _add,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add picture'),
            )
          else
            Text(
              'This person has the maximum of $maxPicturesPerPerson pictures. '
              'Delete one to add another.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _PictureTile extends StatelessWidget {
  const _PictureTile({
    required this.picture,
    required this.enabled,
    required this.onTap,
    required this.onDelete,
  });

  final PersonPicture picture;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = AppConfig.mediaUrl(picture.profilePictureUrl);

    return Stack(
      fit: StackFit.expand,
      children: [
        Material(
          color: scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: picture.isPrimary
                ? BorderSide(color: scheme.primary, width: 3)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('picture-${picture.id}'),
            onTap: enabled ? onTap : null,
            child: url == null
                // A path the server would not sign — a retired /profile-images/
                // row that the backfill carried across. Nothing to show.
                ? Icon(Icons.broken_image_outlined, color: scheme.outline)
                : CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, _, _) =>
                        Icon(Icons.broken_image_outlined, color: scheme.outline),
                  ),
          ),
        ),
        if (picture.isPrimary)
          Positioned(
            left: 4,
            bottom: 4,
            child: _Badge(
              color: scheme.primary,
              foreground: scheme.onPrimary,
              icon: Icons.check,
              label: 'Shown',
            ),
          ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            key: ValueKey('delete-picture-${picture.id}'),
            tooltip: 'Delete picture',
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: scheme.surface.withValues(alpha: 0.8),
            ),
            onPressed: enabled ? onDelete : null,
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.color,
    required this.foreground,
    required this.icon,
    required this.label,
  });

  final Color color;
  final Color foreground;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
