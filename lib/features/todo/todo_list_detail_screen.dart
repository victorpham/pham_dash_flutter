import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_date.dart';
import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/async_view.dart';
import '../../data/models/todo_models.dart';
import 'todo_screen.dart';

final todoListDetailProvider =
    FutureProvider.autoDispose.family<TodoList?, int>(
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

    return Scaffold(
      appBar: AppBar(
        title: Text(list.value?.title ?? 'List'),
        actions: [
          if (list.value != null)
            PopupMenuButton<String>(
              onSelected: (action) => _onAction(context, ref, action),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                const PopupMenuItem(value: 'schedule', child: Text('Schedule…')),
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
        final title = await _prompt(context, 'Rename list', list.title);
        if (title == null) return;
        await repository.updateList(listId, UpdateTodoList(title: title));

      case 'schedule':
        if (!context.mounted) return;
        await _editSchedule(context, ref, list);

      case 'group':
        if (!context.mounted) return;
        final name = await _prompt(context, 'Group name', '');
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
    final content = await _prompt(context, 'Add item', '');
    if (content == null) return;

    try {
      await ref.read(todoRepositoryProvider).addItem(listId, content: content);
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    }
    ref.invalidate(todoListDetailProvider(listId));
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
        if (list.scheduledTime != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 15, color: scheme.mutedForeground),
                const SizedBox(width: 6),
                Text(
                  _scheduleSummary(list),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),

        // Ungrouped items, then each group — the split the API returns.
        for (final item in list.items)
          _ItemRow(listId: list.id, item: item),

        for (final group in list.groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
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
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () async {
                    await ref
                        .read(todoRepositoryProvider)
                        .deleteGroup(group.id);
                    ref.invalidate(todoListDetailProvider(list.id));
                  },
                ),
              ],
            ),
          ),
          for (final item in group.items)
            _ItemRow(listId: list.id, item: item, inGroup: true),
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

  static String _scheduleSummary(TodoList list) {
    final days = list.scheduledDaySet;
    if (days.isEmpty) return '${list.scheduledTime} · every day';

    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final sorted = days.toList()..sort();
    return '${list.scheduledTime} · ${sorted.map((d) => names[d]).join(', ')}';
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({
    required this.listId,
    required this.item,
    this.inGroup = false,
  });

  final int listId;
  final TodoItem item;
  final bool inGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final repository = ref.read(todoRepositoryProvider);

    return Dismissible(
      key: ValueKey(item.id),
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
          final content = await _prompt(context, 'Edit item', item.content);
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
            8,
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
              if (item.indentLevel < 2)
                IconButton(
                  visualDensity: VisualDensity.compact,
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
                  icon: const Icon(Icons.format_indent_decrease, size: 18),
                  onPressed: () async {
                    await repository.updateItem(
                      item.id,
                      UpdateTodoItem(indentLevel: item.indentLevel - 1),
                    );
                    ref.invalidate(todoListDetailProvider(listId));
                  },
                ),
            ],
          ),
        ),
      ),
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

Future<String?> _prompt(
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
