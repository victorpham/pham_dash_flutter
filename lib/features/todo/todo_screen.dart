import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/async_view.dart';
import '../../data/models/todo_models.dart';

final showArchivedProvider = valueProvider<bool>(() => false);

/// Null means "all labels".
final labelFilterProvider = valueProvider<int?>(() => null);

final todoListsProvider =
    FutureProvider.autoDispose<List<TodoList>>((ref) async {
  final includeArchived = ref.watch(showArchivedProvider);
  final labelId = ref.watch(labelFilterProvider);

  final repository = ref.watch(todoRepositoryProvider);
  if (labelId != null) return repository.listsWithLabel(labelId);
  return repository.lists(includeArchived: includeArchived);
});

final todoLabelsProvider = FutureProvider.autoDispose<List<TodoLabel>>(
  (ref) => ref.watch(todoRepositoryProvider).labels(),
);

/// The full todo screen: a card grid of lists with pinned ones first.
class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key, this.openListId});

  /// Deep link — `/todo?openListId=7` opens that list straight away. The
  /// dashboard's Lists tab uses this to jump into a list.
  final int? openListId;

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  @override
  void initState() {
    super.initState();
    final id = widget.openListId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push('/todo/$id');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lists = ref.watch(todoListsProvider);
    final showArchived = ref.watch(showArchivedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo Lists'),
        actions: [
          IconButton(
            tooltip: showArchived ? 'Hide archived' : 'Show archived',
            icon: Icon(showArchived ? Icons.archive : Icons.archive_outlined),
            onPressed: () => ref
                .read(showArchivedProvider.notifier)
                .value = !showArchived,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(46),
          child: _LabelFilterBar(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createList,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(todoListsProvider.future),
        child: AsyncView<List<TodoList>>(
          value: lists,
          onRetry: () => ref.invalidate(todoListsProvider),
          emptyIcon: Icons.checklist,
          emptyTitle: 'No lists yet',
          emptyMessage: 'Tap + to make one.',
          builder: (data) {
            // The API already orders pinned-first, but the web renders them as
            // their own section rather than relying on ordering alone.
            final pinned = data.where((l) => l.isPinned).toList();
            final rest = data.where((l) => !l.isPinned).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
              children: [
                if (pinned.isNotEmpty) ...[
                  const _SectionLabel('Pinned'),
                  for (final list in pinned) TodoListCard(list: list),
                  const SizedBox(height: 8),
                ],
                if (rest.isNotEmpty && pinned.isNotEmpty)
                  const _SectionLabel('All lists'),
                for (final list in rest) TodoListCard(list: list),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _createList() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New list'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'List title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (title == null || title.isEmpty) return;

    final created = await ref
        .read(todoRepositoryProvider)
        .createList(CreateTodoList(title: title));
    ref.invalidate(todoListsProvider);

    if (created != null && mounted) {
      if (!context.mounted) return;
      context.push('/todo/${created.id}');
    }
  }
}

class _LabelFilterBar extends ConsumerWidget {
  const _LabelFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = ref.watch(todoLabelsProvider).value ?? const [];
    final selected = ref.watch(labelFilterProvider);

    if (labels.isEmpty) return const SizedBox(height: 46);

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) =>
                  ref.read(labelFilterProvider.notifier).value = null,
            ),
          ),
          for (final label in labels)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text('${label.name} (${label.listCount})'),
                selected: selected == label.id,
                backgroundColor: parseHexColor(label.color),
                onSelected: (isSelected) => ref
                    .read(labelFilterProvider.notifier)
                    .value = isSelected ? label.id : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
        ),
      );
}

class TodoListCard extends ConsumerWidget {
  const TodoListCard({super.key, required this.list});

  final TodoList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final stripe = parseHexColor(list.color);
    final progress =
        list.totalItems == 0 ? 0.0 : list.completedItems / list.totalItems;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (stripe != null) Container(width: 4, color: stripe),
            Expanded(
              child: InkWell(
                onTap: () => context.push('/todo/${list.id}'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              list.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (list.isArchived)
                            Icon(
                              Icons.archive_outlined,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: list.isPinned ? 'Unpin' : 'Pin',
                            icon: Icon(
                              list.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              size: 18,
                              color: list.isPinned ? scheme.primary : null,
                            ),
                            // Pin is a server-side toggle, not a setter.
                            onPressed: () async {
                              await ref
                                  .read(todoRepositoryProvider)
                                  .togglePin(list.id);
                              ref.invalidate(todoListsProvider);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (list.personName != null) ...[
                            Icon(
                              Icons.person_outline,
                              size: 13,
                              color: scheme.mutedForeground,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              list.personName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.mutedForeground,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (list.scheduledTime != null) ...[
                            Icon(
                              Icons.schedule,
                              size: 13,
                              color: scheme.mutedForeground,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              list.scheduledTime!,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.mutedForeground,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            '${list.completedItems}/${list.totalItems}',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      if (list.totalItems > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                      if (list.labels.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final label in list.labels)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: parseHexColor(label.color) ??
                                      scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  label.name,
                                  style: const TextStyle(fontSize: 10.5),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
