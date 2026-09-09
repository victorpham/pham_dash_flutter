import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/todo_models.dart';
import 'todo_list_detail_screen.dart';
import 'todo_screen.dart';

/// Labels on one list, and the label vocabulary behind them.
///
/// The web keeps these in two places — a multiselect inside the list editor and
/// a separate manage dialog. There is little enough of either to hold them in
/// one sheet: tick a label to attach it, use its menu to rename, recolour or
/// delete it everywhere.
Future<void> showTodoLabelsSheet(
  BuildContext context, {
  required TodoList list,
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
          _LabelsSheet(list: list, scrollController: controller),
    ),
  );
}

class _LabelsSheet extends ConsumerStatefulWidget {
  const _LabelsSheet({required this.list, required this.scrollController});

  final TodoList list;
  final ScrollController scrollController;

  @override
  ConsumerState<_LabelsSheet> createState() => _LabelsSheetState();
}

class _LabelsSheetState extends ConsumerState<_LabelsSheet> {
  /// Attached label ids, held locally so a tick registers immediately — each
  /// attach and detach is its own request, and the list is not re-read until
  /// the sheet closes.
  late Set<int> _attached =
      widget.list.labels.map((label) => label.id).toSet();

  @override
  Widget build(BuildContext context) {
    final labels = ref.watch(todoLabelsProvider);

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
                  'Labels',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: _createLabel,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
              ),
            ],
          ),
        ),
        switch (labels) {
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
                'No labels yet. Create one to group lists across the todo '
                'screen.',
              ),
            ),
          AsyncValue(value: final data) => Column(
              children: [
                for (final label in data!) _LabelRow(
                  label: label,
                  attached: _attached.contains(label.id),
                  onToggle: () => _toggle(label),
                  onEdit: () => _editLabel(label),
                  onDelete: () => _deleteLabel(label),
                ),
              ],
            ),
        },
      ],
    );
  }

  Future<void> _toggle(TodoLabel label) async {
    final repository = ref.read(todoRepositoryProvider);
    final attaching = !_attached.contains(label.id);
    setState(() {
      if (attaching) {
        _attached = {..._attached, label.id};
      } else {
        _attached = {..._attached}..remove(label.id);
      }
    });

    try {
      if (attaching) {
        await repository.addLabelToList(widget.list.id, label.id);
      } else {
        await repository.removeLabelFromList(widget.list.id, label.id);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      // The optimistic tick is now a lie; put it back.
      setState(() {
        if (attaching) {
          _attached = {..._attached}..remove(label.id);
        } else {
          _attached = {..._attached, label.id};
        }
      });
      _toast(error.message);
      return;
    }
    ref.invalidate(todoLabelsProvider);
  }

  Future<void> _createLabel() async {
    final result = await _promptForLabel(context);
    if (result == null) return;

    try {
      await ref
          .read(todoRepositoryProvider)
          .createLabel(result.name, color: result.color);
    } on ApiException catch (error) {
      if (mounted) _toast(error.message);
      return;
    }
    ref.invalidate(todoLabelsProvider);
  }

  Future<void> _editLabel(TodoLabel label) async {
    final result = await _promptForLabel(context, label: label);
    if (result == null) return;

    try {
      await ref
          .read(todoRepositoryProvider)
          .updateLabel(label.id, name: result.name, color: result.color);
    } on ApiException catch (error) {
      if (mounted) _toast(error.message);
      return;
    }
    ref.invalidate(todoLabelsProvider);
  }

  Future<void> _deleteLabel(TodoLabel label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${label.name}"?'),
        content: Text(
          label.listCount == 0
              ? 'This label is not on any list.'
              : 'It comes off ${label.listCount} '
                  '${label.listCount == 1 ? 'list' : 'lists'}. The lists '
                  'themselves are untouched.',
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
      await ref.read(todoRepositoryProvider).deleteLabel(label.id);
    } on ApiException catch (error) {
      if (mounted) _toast(error.message);
      return;
    }
    setState(() => _attached = {..._attached}..remove(label.id));
    ref.invalidate(todoLabelsProvider);
    // The filter bar may be pointing at a label that no longer exists.
    ref.read(labelFilterProvider.notifier).value = null;
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({
    required this.label,
    required this.attached,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final TodoLabel label;
  final bool attached;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onToggle,
      leading: Checkbox(value: attached, onChanged: (_) => onToggle()),
      title: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: parseHexColor(label.color) ?? scheme.outlineVariant,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(label.name)),
        ],
      ),
      subtitle: Text(
        '${label.listCount} ${label.listCount == 1 ? 'list' : 'lists'}',
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

/// Name and colour for a new or edited label.
Future<({String name, String? color})?> _promptForLabel(
  BuildContext context, {
  TodoLabel? label,
}) {
  return showDialog<({String name, String? color})>(
    context: context,
    builder: (context) => _LabelDialog(label: label),
  );
}

class _LabelDialog extends StatefulWidget {
  const _LabelDialog({this.label});

  final TodoLabel? label;

  @override
  State<_LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<_LabelDialog> {
  late final _name = TextEditingController(text: widget.label?.name);
  late String? _color = widget.label?.color;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The list swatches without "None" — the same palette the web label editor
    // offers.
    final options = kListColors.skip(1).toList();

    return AlertDialog(
      title: Text(widget.label == null ? 'New label' : 'Edit label'),
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
