import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_date.dart';
import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/person_picker.dart';
import '../../data/models/todo_models.dart';
import '../people/people_providers.dart';
import 'todo_labels_sheet.dart';
import 'todo_screen.dart';

final todoListDetailProvider =
    FutureProvider.autoDispose.family<TodoList?, int>(
  (ref, id) => ref.watch(todoRepositoryProvider).list(id),
);

/// The eight swatches the web editor offers, in its order. Pastels, because a
/// list's colour is a background wash on the web card rather than an accent.
const List<({String name, String? value})> kListColors = [
  (name: 'None', value: null),
  (name: 'Red', value: '#fee2e2'),
  (name: 'Orange', value: '#ffedd5'),
  (name: 'Yellow', value: '#fef9c3'),
  (name: 'Green', value: '#dcfce7'),
  (name: 'Blue', value: '#dbeafe'),
  (name: 'Purple', value: '#e9d5ff'),
  (name: 'Pink', value: '#fce7f3'),
];

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
                const PopupMenuItem(value: 'schedule', child: Text('Schedule…')),
                const PopupMenuItem(value: 'person', child: Text('Link person…')),
                const PopupMenuItem(value: 'labels', child: Text('Labels…')),
                const PopupMenuItem(value: 'group', child: Text('Add group')),
                const PopupMenuItem(value: 'reset', child: Text('Reset items')),
                PopupMenuItem(
                  value: 'archive',
                  child: Text(
                    list.value!.isArchived ? 'Unarchive' : 'Archive',
                  ),
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
    final content = await promptForText(context, 'Add item', '');
    if (content == null) return;

    try {
      await ref.read(todoRepositoryProvider).addItem(listId, content: content);
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
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
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

    await ref.read(todoRepositoryProvider).updateList(
          list.id,
          UpdateTodoList(personId: selected.id),
        );
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

    await ref.read(todoRepositoryProvider).updateList(
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
          onReorder: (ordering) =>
              _reorder(context, ref, ungrouped: ordering),
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
    final ordering =
        list.reorderPayload(ungrouped: ungrouped, groups: groupOrderings);

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
    final hasAny = list.scheduledTime != null ||
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
                color: parseHexColor(label.color) ??
                    scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label.name,
                style: const TextStyle(fontSize: 11.5),
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
  });

  final int listId;
  final TodoItem item;
  final int index;
  final bool inGroup;

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
        onLongPress: () async {
          final content =
              await promptForText(context, 'Edit item', item.content);
          if (content == null) return;
          await repository.updateItem(
            item.id,
            UpdateTodoItem(content: content),
          );
          ref.invalidate(todoListDetailProvider(listId));
        },
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
              Expanded(
                child: Text(
                  item.content,
                  style: TextStyle(
                    fontSize: 15,
                    color: item.isCompleted
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                    decoration:
                        item.isCompleted ? TextDecoration.lineThrough : null,
                  ),
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
  });

  final ({String name, String? value}) option;
  final bool selected;
  final VoidCallback onTap;

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
                    Icons.format_color_reset_outlined,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  )
                : null,
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule),
            label: Text(
              _time == null ? 'Pick a time' : _time!.format(context),
            ),
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
                  onPressed: () => Navigator.of(context)
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

/// A one-field text dialog, returning the trimmed value or null.
Future<String?> promptForText(
  BuildContext context,
  String title,
  String initial,
) async {
  final controller = TextEditingController(text: initial);

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
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
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );

  controller.dispose();
  return (result == null || result.isEmpty) ? null : result;
}

void _toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
