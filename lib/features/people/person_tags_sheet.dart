import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/people_models.dart';
import 'people_providers.dart';
import 'people_screen.dart';

/// Tags on one person, and the tag vocabulary behind them.
///
/// A port of `todo_labels_sheet.dart`, which already solved the same two jobs in
/// one place: tick a tag to put it on the person, use its menu to rename,
/// recolour or delete it everywhere.
///
/// Pass [person] to attach and detach. Omit it — from the "Manage tags" action
/// on the people screen — and the same list renders without checkboxes, purely
/// as the vocabulary editor. That one parameter is why there is no separate
/// manage screen.
Future<void> showPersonTagsSheet(
  BuildContext context, {
  Person? person,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) =>
          PersonTagList(person: person, scrollController: controller),
    ),
  );
}

/// The tag list itself, exposed so a widget test can pump it without a
/// navigator or a modal route.
class PersonTagList extends ConsumerStatefulWidget {
  const PersonTagList({super.key, this.person, this.scrollController});

  /// Null renders the vocabulary alone, with no checkboxes and no attaching.
  final Person? person;
  final ScrollController? scrollController;

  @override
  ConsumerState<PersonTagList> createState() => _PersonTagListState();
}

class _PersonTagListState extends ConsumerState<PersonTagList> {
  /// Attached tag ids, held locally so a tick registers immediately — each
  /// attach and detach is its own request, and the person is not re-read until
  /// the sheet closes.
  late Set<int> _attached = {...?widget.person?.tags.map((tag) => tag.id)};

  bool get _attaching => widget.person != null;

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(personTagsProvider);

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _attaching ? 'Tags for ${widget.person!.firstName}' : 'Tags',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: _createTag,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
              ),
            ],
          ),
        ),
        switch (tags) {
          AsyncError(:final error) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                error is ApiException ? error.message : 'Something went wrong.',
              ),
            ),
          AsyncValue(hasValue: false) => const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            ),
          AsyncValue(value: final data) when (data ?? const []).isEmpty =>
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Text(
                'No tags yet. Create one to group people — "Pickleball '
                'Friends", say — and filter the directory by it.',
              ),
            ),
          AsyncValue(value: final data) => Column(
              children: [
                for (final tag in data!) _TagRow(
                  tag: tag,
                  attached: _attached.contains(tag.id),
                  onToggle: _attaching ? () => _toggle(tag) : null,
                  onEdit: () => _editTag(tag),
                  onDelete: () => _deleteTag(tag),
                ),
              ],
            ),
        },
      ],
    );
  }

  Future<void> _toggle(PersonTag tag) async {
    final person = widget.person!;
    final repository = ref.read(personTagsRepositoryProvider);
    final attaching = !_attached.contains(tag.id);
    setState(() {
      if (attaching) {
        _attached = {..._attached, tag.id};
      } else {
        _attached = {..._attached}..remove(tag.id);
      }
    });

    try {
      if (attaching) {
        await repository.attach(person.id, tag.id);
      } else {
        await repository.detach(person.id, tag.id);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      // The optimistic tick is now a lie; put it back.
      setState(() {
        if (attaching) {
          _attached = {..._attached}..remove(tag.id);
        } else {
          _attached = {..._attached, tag.id};
        }
      });
      _toast(error.message);
      return;
    }
    if (!mounted) return;
    invalidatePerson(ref, person.id);
  }

  Future<void> _createTag() async {
    final result = await promptForPersonTag(context);
    if (result == null) return;

    try {
      await ref
          .read(personTagsRepositoryProvider)
          .create(result.name, color: result.color);
    } on ApiException catch (error) {
      if (mounted) _toast(error.message);
      return;
    }
    if (mounted) invalidateTags(ref);
  }

  Future<void> _editTag(PersonTag tag) async {
    final result = await promptForPersonTag(context, tag: tag);
    if (result == null) return;

    try {
      await ref
          .read(personTagsRepositoryProvider)
          .update(tag.id, name: result.name, color: result.color);
    } on ApiException catch (error) {
      if (mounted) _toast(error.message);
      return;
    }
    // Wider than the vocabulary: the old name and colour are embedded on every
    // person already loaded, so the directory has to be re-read too.
    if (mounted) invalidateTags(ref);
  }

  Future<void> _deleteTag(PersonTag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${tag.name}"?'),
        content: Text(
          tag.personCount == 0
              ? 'This tag is not on anyone.'
              // Spelled out because the vocabulary is shared: unlike a todo
              // label this is not "your" tag, and the delete is not undoable
              // from anyone else's phone either.
              : 'It comes off ${tag.personCount} '
                  '${tag.personCount == 1 ? 'person' : 'people'} — for '
                  'everyone, not just you. The people themselves are '
                  'untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(personTagsRepositoryProvider).delete(tag.id);
    } on ApiException catch (error) {
      if (mounted) _toast(error.message);
      return;
    }
    if (!mounted) return;
    setState(() => _attached = {..._attached}..remove(tag.id));
    invalidateTags(ref);
    // The filter bar may be pointing at a tag that no longer exists.
    ref.read(tagFilterProvider.notifier).value = null;
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tag,
    required this.attached,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final PersonTag tag;
  final bool attached;

  /// Null when the sheet was opened without a person — the vocabulary is being
  /// managed, not applied, so there is nothing to tick.
  final VoidCallback? onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onToggle,
      leading: onToggle == null
          ? Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: parseHexColor(tag.color) ?? scheme.outlineVariant,
                shape: BoxShape.circle,
              ),
            )
          : Checkbox(
              value: attached,
              onChanged: (_) => onToggle!(),
            ),
      title: Row(
        children: [
          if (onToggle != null) ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: parseHexColor(tag.color) ?? scheme.outlineVariant,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: Text(tag.name)),
        ],
      ),
      subtitle: Text(
        '${tag.personCount} ${tag.personCount == 1 ? 'person' : 'people'}',
        style: TextStyle(fontSize: 12, color: scheme.mutedForeground),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 18),
        onSelected: (action) => action == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}

/// Name and colour for a new or edited tag.
Future<({String name, String? color})?> promptForPersonTag(
  BuildContext context, {
  PersonTag? tag,
}) {
  return showDialog<({String name, String? color})>(
    context: context,
    builder: (context) => _TagDialog(tag: tag),
  );
}

class _TagDialog extends StatefulWidget {
  const _TagDialog({this.tag});

  final PersonTag? tag;

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  late final _name = TextEditingController(text: widget.tag?.name);
  late String? _color = widget.tag?.color;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The shared swatches without "None" — the same palette the label editor
    // offers.
    final options = kListColors.skip(1).toList();

    return AlertDialog(
      title: Text(widget.tag == null ? 'New tag' : 'Edit tag'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                InkWell(
                  onTap: () => setState(() => _color = option.value),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: parseHexColor(option.value),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == option.value
                            ? scheme.primary
                            : scheme.outlineVariant,
                        width: _color == option.value ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _name.text.trim().isEmpty
              ? null
              : () => Navigator.of(context)
                  .pop((name: _name.text.trim(), color: _color)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
