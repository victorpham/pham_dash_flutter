import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_date.dart';
import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/color_picker_sheet.dart';
import '../../core/ui/person_picker.dart';
import '../../data/models/todo_models.dart';
import '../people/people_providers.dart';
import 'todo_item_image.dart';
import 'todo_labels_sheet.dart';
import 'todo_providers.dart';

final todoListDetailProvider = FutureProvider.autoDispose
    .family<TodoList?, int>(
      (ref, id) => ref.watch(todoRepositoryProvider).list(id),
    );

/// The list editor.
///
/// Deliberately **not** a port of the web save routine, which recomputes a full
/// client-side diff and issues N+M requests on every save. Each edit here is a
/// single targeted call, followed by a re-read of the list.
class TodoListDetailScreen extends ConsumerWidget {
  const TodoListDetailScreen({super.key, required this.listId});

  final int listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(todoListDetailProvider(listId));
    final stripe = parseHexColor(list.value?.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(list.value?.title ?? 'List'),
        // The list's colour is a wash behind the whole card on the web; an
        // app-bar tint is the closest thing that does not fight the theme.
        backgroundColor: stripe?.withValues(alpha: 0.35),
        actions: [
          if (list.value != null)
            PopupMenuButton<String>(
              onSelected: (action) => _onAction(context, ref, action),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                const PopupMenuItem(value: 'color', child: Text('Colour…')),
                const PopupMenuItem(
                  value: 'schedule',
                  child: Text('Schedule…'),
                ),
                const PopupMenuItem(
                  value: 'person',
                  child: Text('Link person…'),
                ),
                const PopupMenuItem(value: 'labels', child: Text('Labels…')),
                const PopupMenuItem(value: 'group', child: Text('Add group')),
                const PopupMenuItem(value: 'reset', child: Text('Reset items')),
                PopupMenuItem(
                  value: 'archive',
                  child: Text(list.value!.isArchived ? 'Unarchive' : 'Archive'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addItem(context, ref),
        child: const Icon(Icons.add),
      ),
      body: AsyncView<TodoList?>(
        value: list,
        onRetry: () => ref.invalidate(todoListDetailProvider(listId)),
        isEmpty: (data) => data == null,
        emptyIcon: Icons.search_off,
        emptyTitle: 'List not found',
        builder: (data) => _ListBody(list: data!),
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final repository = ref.read(todoRepositoryProvider);
    final list = ref.read(todoListDetailProvider(listId)).value;
    if (list == null) return;

    switch (action) {
      case 'rename':
        final title = await promptForText(context, 'Rename list', list.title);
        if (title == null) return;
        await repository.updateList(listId, UpdateTodoList(title: title));

      case 'color':
        if (!context.mounted) return;
        final picked = await _pickColor(context, list.color);
        if (picked == null) return;
        await repository.updateList(
          listId,
          // "None" clears through the empty string; null would be ignored.
          UpdateTodoList(color: picked.value ?? kClearColor),
        );

      case 'schedule':
        if (!context.mounted) return;
        await _editSchedule(context, ref, list);
        return;

      case 'person':
        if (!context.mounted) return;
        await _linkPerson(context, ref, list);
        return;

      case 'labels':
        if (!context.mounted) return;
        await showTodoLabelsSheet(context, list: list);
        ref.invalidate(todoListDetailProvider(listId));
        ref.invalidate(todoListsProvider);
        ref.invalidate(todoLabelsProvider);
        return;

      case 'group':
        if (!context.mounted) return;
        final name = await promptForText(context, 'Group name', '');
        if (name == null) return;
        await repository.addGroup(listId, name);

      case 'reset':
        await repository.resetItems(listId);

      case 'archive':
        // A toggle, not a setter.
        await repository.toggleArchive(listId);

      case 'delete':
        if (!context.mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete "${list.title}"?'),
            content: const Text('This cannot be undone.'),
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
        await repository.deleteList(listId);
        ref.invalidate(todoListsProvider);
        if (context.mounted) Navigator.of(context).pop();
        return;
    }

    ref.invalidate(todoListDetailProvider(listId));
    ref.invalidate(todoListsProvider);
  }

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final entered = await promptForItem(context, 'Add item');
    if (entered == null) return;

    try {
      await ref
          .read(todoRepositoryProvider)
          .addItem(
            listId,
            content: entered.content,
            location: entered.location,
          );
    } on ApiException catch (error) {
      if (context.mounted) _toast(context, error.message);
      return;
    }
    ref.invalidate(todoListDetailProvider(listId));
    ref.invalidate(todoListsProvider);
  }

  Future<({String name, String? value})?> _pickColor(
    BuildContext context,
    String? current,
  ) {
    return showModalBottomSheet<({String name, String? value})>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Colour',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final option in kListColors)
                    _ColorSwatch(
                      option: option,
                      selected: (option.value ?? '') == (current ?? ''),
                      onTap: () => Navigator.of(context).pop(option),
                    ),
                  // Anything outside the eight presets. Shows the current
                  // colour when it is already a custom one, so reopening the
                  // sheet does not look like it forgot.
                  _ColorSwatch(
                    option: (
                      name: 'Custom',
                      value: kListColors.any((o) => o.value == current)
                          ? null
                          : current,
                    ),
                    icon: Icons.colorize_outlined,
                    selected:
                        current != null &&
                        !kListColors.any((o) => o.value == current),
                    onTap: () async {
                      final picked = await showColorPicker(
                        context,
                        initial: current,
                      );
                      if (picked != null && context.mounted) {
                        Navigator.of(context)
                            .pop((name: 'Custom', value: picked));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _linkPerson(
    BuildContext context,
    WidgetRef ref,
    TodoList list,
  ) async {
    final people = await ref.read(allPeopleProvider.future);
    if (!context.mounted) return;

    final selected = await pickPerson(
      context,
      people: people,
      title: 'Search people',
    );
    if (selected == null) return;

    await ref
        .read(todoRepositoryProvider)
        .updateList(list.id, UpdateTodoList(personId: selected.id));
    ref.invalidate(todoListDetailProvider(list.id));
    ref.invalidate(todoListsProvider);
  }

  Future<void> _editSchedule(
    BuildContext context,
    WidgetRef ref,
    TodoList list,
  ) async {
    final result = await showModalBottomSheet<_ScheduleResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ScheduleSheet(list: list),
    );
    if (result == null) return;

    await ref
        .read(todoRepositoryProvider)
        .updateList(
          listId,
          result.clear
              // Sending nulls would be ignored — clearScheduledTime is the only
              // way to remove a schedule, and it clears the days too.
              ? const UpdateTodoList(clearSchedule: true)
              : UpdateTodoList(
                  scheduledTime: result.time,
                  scheduledDays: result.days,
                ),
        );
    ref.invalidate(todoListDetailProvider(listId));
    ref.invalidate(todoListsProvider);
  }
}

class _ListBody extends ConsumerWidget {
  const _ListBody({required this.list});

  final TodoList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        _Attributes(list: list),

        // Ungrouped items, then each group — the split the API returns.
        _ItemSection(
          list: list,
          items: list.items,
          onReorder: (ordering) => _reorder(context, ref, ungrouped: ordering),
        ),

        for (final group in list.groups) ...[
          _GroupHeader(list: list, group: group),
          _ItemSection(
            list: list,
            items: group.items,
            inGroup: true,
            onReorder: (ordering) =>
                _reorder(context, ref, groupOrderings: {group.id: ordering}),
          ),
        ],

        if (list.allItems.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No items yet. Tap + to add one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  /// Sends the whole list's ordering, with one section replaced — see
  /// [TodoList.reorderPayload] for why it cannot be just the section.
  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref, {
    List<int>? ungrouped,
    Map<int, List<int>> groupOrderings = const {},
  }) async {
    final ordering = list.reorderPayload(
      ungrouped: ungrouped,
      groups: groupOrderings,
    );

    try {
      await ref.read(todoRepositoryProvider).reorderItems(list.id, ordering);
    } on ApiException catch (error) {
      if (context.mounted) _toast(context, error.message);
    } finally {
      // Re-read either way: on success to pick up the new displayOrders, on
      // failure to put the rows back where the server still has them.
      ref.invalidate(todoListDetailProvider(list.id));
      ref.invalidate(todoListsProvider);
    }
  }
}

/// The list's colour, person and labels, each a tap away from its editor.
class _Attributes extends ConsumerWidget {
  const _Attributes({required this.list});

  final TodoList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final hasAny =
        list.scheduledTime != null ||
        list.personName != null ||
        list.labels.isNotEmpty;
    if (!hasAny) return const SizedBox(height: 8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (list.scheduledTime != null)
            _Meta(icon: Icons.schedule, text: _scheduleSummary(list)),
          if (list.personName case final person?)
            _Meta(icon: Icons.person_outline, text: person),
          for (final label in list.labels)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:
                    parseHexColor(label.color) ??
                    scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label.name,
                style: TextStyle(
                  fontSize: 11.5,
                  color: onColor(
                    parseHexColor(label.color) ??
                        scheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _scheduleSummary(TodoList list) {
    final days = list.scheduledDaySet;
    if (days.isEmpty) return '${list.scheduledTime} · every day';

    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final sorted = days.toList()..sort();
    return '${list.scheduledTime} · ${sorted.map((d) => names[d]).join(', ')}';
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.mutedForeground),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(fontSize: 12.5, color: scheme.mutedForeground),
        ),
      ],
    );
  }
}

class _GroupHeader extends ConsumerWidget {
  const _GroupHeader({required this.list, required this.group});

  final TodoList list;
  final TodoItemGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final index = list.groups.indexOf(group);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 4, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              group.name,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: scheme.mutedForeground,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, size: 18),
            onSelected: (action) => _onAction(context, ref, action, index),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'rename', child: Text('Rename')),
              // Groups reorder a step at a time rather than by dragging: their
              // headers sit between two reorderable item lists, and a drag that
              // could mean either is worse than a button that cannot.
              if (index > 0)
                const PopupMenuItem(value: 'up', child: Text('Move up')),
              if (index < list.groups.length - 1)
                const PopupMenuItem(value: 'down', child: Text('Move down')),
              const PopupMenuItem(value: 'delete', child: Text('Delete group')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    int index,
  ) async {
    final repository = ref.read(todoRepositoryProvider);

    switch (action) {
      case 'rename':
        final name = await promptForText(context, 'Rename group', group.name);
        if (name == null) return;
        await repository.updateGroup(group.id, name: name);

      case 'up' || 'down':
        final ids = list.groups.map((g) => g.id).toList();
        final target = action == 'up' ? index - 1 : index + 1;
        ids
          ..removeAt(index)
          ..insert(target, group.id);
        // A bare JSON array, unlike the item reorder's `{ itemIds: [...] }`.
        await repository.reorderGroups(list.id, ids);

      case 'delete':
        await repository.deleteGroup(group.id);
    }

    ref.invalidate(todoListDetailProvider(list.id));
    ref.invalidate(todoListsProvider);
  }
}

/// One draggable run of items — the ungrouped ones, or a single group's.
///
/// Reordering is optimistic: the rows settle where they were dropped and stay
/// there while the request is in flight, rather than snapping back to the
/// server's order until the re-read lands.
class _ItemSection extends ConsumerStatefulWidget {
  const _ItemSection({
    required this.list,
    required this.items,
    required this.onReorder,
    this.inGroup = false,
  });

  final TodoList list;
  final List<TodoItem> items;
  final bool inGroup;
  final Future<void> Function(List<int> ordering) onReorder;

  @override
  ConsumerState<_ItemSection> createState() => _ItemSectionState();
}

class _ItemSectionState extends ConsumerState<_ItemSection> {
  late List<TodoItem> _items = widget.items;

  @override
  void didUpdateWidget(_ItemSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A re-read has landed (or an item was added, toggled or deleted): the
    // server's order is authoritative again.
    if (!identical(widget.items, oldWidget.items)) _items = widget.items;
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // The rows already spend their long-press on editing and their horizontal
      // drag on deleting, so dragging is confined to an explicit handle.
      buildDefaultDragHandles: false,
      itemCount: _items.length,
      itemBuilder: (context, index) => _ItemRow(
        key: ValueKey(_items[index].id),
        listId: widget.list.id,
        item: _items[index],
        index: index,
        inGroup: widget.inGroup,
        groups: widget.list.groups,
      ),
      // `onReorderItem` hands over a newIndex already adjusted for the removal,
      // unlike the deprecated `onReorder`.
      onReorderItem: (oldIndex, newIndex) {
        setState(() {
          final next = [..._items];
          next.insert(newIndex, next.removeAt(oldIndex));
          _items = next;
        });
        widget.onReorder(_items.map((item) => item.id).toList());
      },
    );
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({
    super.key,
    required this.listId,
    required this.item,
    required this.index,
    this.inGroup = false,
    this.groups = const [],
  });

  final int listId;
  final TodoItem item;
  final int index;
  final bool inGroup;

  /// The list's groups, for **Move to group…**. Empty hides that action.
  final List<TodoItemGroup> groups;

  /// Long-press menu. Used to go straight to the text prompt; the picture
  /// actions needed somewhere to live and a second gesture would have been
  /// worse than one more tap.
  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<_ItemAction>(
      context: context,
      showDragHandle: true,
      // Scrollable: with the picture and group actions the sheet can outgrow a
      // short screen's modal-sheet allowance rather than just a long one's.
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  item.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit item…'),
                onTap: () => Navigator.pop(context, _ItemAction.edit),
              ),
              if (groups.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.drive_file_move_outline),
                  title: const Text('Move to group…'),
                  onTap: () => Navigator.pop(context, _ItemAction.moveToGroup),
                ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(context, _ItemAction.takePhoto),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, _ItemAction.choosePhoto),
              ),
              if (item.imageUrl != null)
                ListTile(
                  leading: const Icon(Icons.hide_image_outlined),
                  title: const Text('Remove photo'),
                  onTap: () => Navigator.pop(context, _ItemAction.removePhoto),
                ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _ItemAction.edit:
        await _editItem(context, ref);
      case _ItemAction.moveToGroup:
        await _moveToGroup(context, ref);
      case _ItemAction.takePhoto:
        await _setPhoto(context, ref, ImageSource.camera);
      case _ItemAction.choosePhoto:
        await _setPhoto(context, ref, ImageSource.gallery);
      case _ItemAction.removePhoto:
        await _removePhoto(context, ref);
    }
  }

  Future<void> _editItem(BuildContext context, WidgetRef ref) async {
    final entered = await promptForItem(
      context,
      'Edit item',
      content: item.content,
      location: item.location,
    );
    if (entered == null) return;

    // An emptied location has to be sent as "" to clear it; leaving it out
    // would keep the old value (the API ignores null).
    final cleared = entered.location == null && item.location != null;
    await ref
        .read(todoRepositoryProvider)
        .updateItem(
          item.id,
          UpdateTodoItem(
            content: entered.content,
            location: entered.location,
            clearLocation: cleared,
          ),
        );
    ref.invalidate(todoListDetailProvider(listId));
    ref.invalidate(todoListsProvider);
  }

  /// Picks a group (or none) and moves the item there. The web editor does this
  /// by dragging between sections; on a phone a picker is the honest version.
  Future<void> _moveToGroup(BuildContext context, WidgetRef ref) async {
    // 0 is the API's own "no group" sentinel, so it doubles as the dialog's.
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Move to group'),
        children: [
          for (final option in [
            (id: 0, name: '(No group)'),
            for (final group in groups) (id: group.id, name: group.name),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, option.id),
              child: Row(
                children: [
                  Expanded(child: Text(option.name)),
                  if (option.id == (item.groupId ?? 0))
                    const Icon(Icons.check, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || picked == (item.groupId ?? 0)) return;

    await ref
        .read(todoRepositoryProvider)
        .updateItem(
          item.id,
          picked == 0
              ? const UpdateTodoItem(removeFromGroup: true)
              : UpdateTodoItem(groupId: picked),
        );
    ref.invalidate(todoListDetailProvider(listId));
    ref.invalidate(todoListsProvider);
  }

  Future<void> _setPhoto(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      // Downscaling is what usually keeps a phone photo under the server's
      // 5 MB ceiling - same numbers the person edit sheet uses.
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;

    final tooLarge = await picked.length() > kMaxItemImageBytes;
    if (!context.mounted) return;
    if (tooLarge) {
      _toast(context, 'That image is larger than 5 MB.');
      return;
    }

    await _runImageWrite(
      context,
      ref,
      () => ref
          .read(todoRepositoryProvider)
          .setItemImage(item.id, filePath: picked.path, fileName: picked.name),
    );
  }

  Future<void> _removePhoto(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this photo?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await _runImageWrite(
      context,
      ref,
      () => ref.read(todoRepositoryProvider).removeItemImage(item.id),
    );
  }

  /// Runs a picture write and re-reads the list. The lists tab is refreshed
  /// too, since its cached copy carries the items and would otherwise show a
  /// stale (or already-signed-out) picture on the next cold start.
  Future<void> _runImageWrite(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() write,
  ) async {
    try {
      await write();
    } on ApiException catch (error) {
      // The 400 for a bad type or size names the allowed types; use it.
      if (context.mounted) _toast(context, error.message);
      return;
    }
    ref.invalidate(todoListDetailProvider(listId));
    ref.invalidate(todoListsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final repository = ref.read(todoRepositoryProvider);

    return Dismissible(
      key: ValueKey('dismiss-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: scheme.errorContainer,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) async {
        await repository.deleteItem(item.id);
        ref.invalidate(todoListDetailProvider(listId));
        ref.invalidate(todoListsProvider);
      },
      child: InkWell(
        onTap: () async {
          await repository.toggleItem(item.id);
          ref.invalidate(todoListDetailProvider(listId));
          ref.invalidate(todoListsProvider);
        },
        onLongPress: () => _showActions(context, ref),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16 + item.indentLevel * 18.0 + (inGroup ? 12 : 0),
            10,
            4,
            10,
          ),
          child: Row(
            children: [
              Icon(
                item.isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 24,
                color: item.isCompleted ? scheme.completed : scheme.outline,
              ),
              const SizedBox(width: 10),
              TodoItemThumbnail(item: item),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: item.isCompleted
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    // Where to find it. Not struck through when done - it is
                    // a fact about the shop, not about the task.
                    if (item.location != null)
                      Text(
                        item.location!,
                        key: ValueKey('item-location-${item.id}'),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Indent is capped at 2, and the first item cannot be indented.
              if (item.indentLevel < 2 && index > 0)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Indent',
                  icon: const Icon(Icons.format_indent_increase, size: 18),
                  onPressed: () async {
                    await repository.updateItem(
                      item.id,
                      UpdateTodoItem(indentLevel: item.indentLevel + 1),
                    );
                    ref.invalidate(todoListDetailProvider(listId));
                  },
                ),
              if (item.indentLevel > 0)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Outdent',
                  icon: const Icon(Icons.format_indent_decrease, size: 18),
                  onPressed: () async {
                    await repository.updateItem(
                      item.id,
                      UpdateTodoItem(indentLevel: item.indentLevel - 1),
                    );
                    ref.invalidate(todoListDetailProvider(listId));
                  },
                ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.drag_handle,
                    size: 20,
                    color: scheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.option,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final ({String name, String? value}) option;
  final bool selected;
  final VoidCallback onTap;

  /// Shown when the swatch has no colour of its own to show. Defaults to the
  /// "no colour" glyph, which is what the None swatch wants.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = parseHexColor(option.value);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color ?? scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 3 : 1,
              ),
            ),
            child: color == null
                ? Icon(
                    icon ?? Icons.format_color_reset_outlined,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  )
                : icon == null
                ? null
                // A custom swatch showing its colour still needs the glyph,
                // or it is indistinguishable from a preset.
                : Icon(icon, size: 18, color: onColor(color)),
          ),
        ),
        const SizedBox(height: 4),
        Text(option.name, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _ScheduleResult {
  const _ScheduleResult({this.time, this.days, this.clear = false});

  final String? time;
  final String? days;
  final bool clear;
}

class _ScheduleSheet extends StatefulWidget {
  const _ScheduleSheet({required this.list});

  final TodoList list;

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  late TimeOfDay? _time = _initialTime();
  late Set<int> _days = widget.list.scheduledDaySet;

  TimeOfDay? _initialTime() {
    final minutes = widget.list.scheduledMinutes;
    if (minutes == null) return null;
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  @override
  Widget build(BuildContext context) {
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Schedule',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule),
            label: Text(_time == null ? 'Pick a time' : _time!.format(context)),
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _time ?? TimeOfDay.now(),
              );
              if (picked != null) setState(() => _time = picked);
            },
          ),
          const SizedBox(height: 16),
          const Text('Repeat on', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (var day = 0; day < 7; day++)
                FilterChip(
                  label: Text(names[day]),
                  selected: _days.contains(day),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _days = {..._days, day};
                    } else {
                      _days = {..._days}..remove(day);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _days.isEmpty ? 'No days selected means every day.' : '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context)
                          .pop(const _ScheduleResult(clear: true)),
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _time == null
                      ? null
                      : () => Navigator.of(context).pop(
                          _ScheduleResult(
                            time: ApiDate.formatMinutesOfDay(
                              _time!.hour * 60 + _time!.minute,
                            ),
                            days: ApiDate.formatScheduledDays(_days) ?? '',
                          ),
                        ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The add / edit item dialog: the text plus an optional location. Returns null
/// on cancel or when the text is blank; a blank location comes back as null so
/// callers can tell "cleared" from "unchanged" against the item they hold.
Future<({String content, String? location})?> promptForItem(
  BuildContext context,
  String title, {
  String content = '',
  String? location,
}) async {
  final result = await showDialog<({String content, String? location})>(
    context: context,
    builder: (_) =>
        _ItemPromptDialog(title: title, content: content, location: location),
  );
  return (result == null || result.content.isEmpty) ? null : result;
}

/// Stateful so the controllers outlive the pop: a dialog keeps building while
/// it animates out, and a controller disposed the moment `showDialog` returns
/// is exactly what that last frame reads.
class _ItemPromptDialog extends StatefulWidget {
  const _ItemPromptDialog({
    required this.title,
    required this.content,
    required this.location,
  });

  final String title;
  final String content;
  final String? location;

  @override
  State<_ItemPromptDialog> createState() => _ItemPromptDialogState();
}

class _ItemPromptDialogState extends State<_ItemPromptDialog> {
  late final _content = TextEditingController(text: widget.content);
  late final _location = TextEditingController(text: widget.location ?? '');

  @override
  void dispose() {
    _content.dispose();
    _location.dispose();
    super.dispose();
  }

  void _save() {
    final where = _location.text.trim();
    Navigator.of(context).pop((
      content: _content.text.trim(),
      location: where.isEmpty ? null : where,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _content,
            autofocus: true,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Item'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Location (optional)',
              hintText: 'Aisle 7, Bakery…',
            ),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

/// A one-field text dialog, returning the trimmed value or null.
Future<String?> promptForText(
  BuildContext context,
  String title,
  String initial,
) async {
  final result = await showDialog<String>(
    context: context,
    builder: (_) => _TextPromptDialog(title: title, initial: initial),
  );
  return (result == null || result.isEmpty) ? null : result;
}

/// Stateful for the same reason as [_ItemPromptDialog].
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 1,
        maxLines: 4,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

void _toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

enum _ItemAction { edit, moveToGroup, takePhoto, choosePhoto, removePhoto }
