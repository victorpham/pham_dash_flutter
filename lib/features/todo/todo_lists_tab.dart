import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/async_view.dart';
import '../../data/models/todo_models.dart';
import 'todo_providers.dart';

/// The dashboard's Lists tab: every list as a card, pinned ones first.
///
/// This was `/todo`, a drawer destination with its own `Scaffold`, and the tab
/// was `ScheduledListsTab` — a port of `ScheduledListsWidget.vue` showing only
/// lists due within minutes, with their items inline. A deliberate divergence
/// from the web, where the mobile shell's Lists tab is still that widget and
/// this browser is drawer-only: a list with no `scheduledTime` never reached the
/// feed, so most of the directory sat two taps into a drawer. The feed was
/// removed rather than relocated.
///
/// Its chrome lives on the shell, not here: [ShowArchivedButton],
/// [TodoLabelFilterBar] and [CreateListButton] are hung off `DashboardTab`,
/// because the tabs render into `DashboardShell`'s `Scaffold`.
class TodoListsTab extends ConsumerWidget {
  const TodoListsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(todoListsProvider);

    return RefreshIndicator(
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
            // The bottom padding clears the shell's 60px bar and its FAB.
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
    );
  }
}

/// Archived lists in or out. Shell-hosted, like [AddNoteButton].
class ShowArchivedButton extends ConsumerWidget {
  const ShowArchivedButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showArchived = ref.watch(showArchivedProvider);

    return IconButton(
      tooltip: showArchived ? 'Hide archived' : 'Show archived',
      icon: Icon(showArchived ? Icons.archive : Icons.archive_outlined),
      onPressed: () =>
          ref.read(showArchivedProvider.notifier).value = !showArchived,
    );
  }
}

/// Creates a list and opens it. Shell-hosted, like [AddNoteButton].
class CreateListButton extends ConsumerWidget {
  const CreateListButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => FloatingActionButton(
        tooltip: 'New list',
        onPressed: () => _createList(context, ref),
        child: const Icon(Icons.add),
      );

  Future<void> _createList(BuildContext context, WidgetRef ref) async {
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
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
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

    if (created != null && context.mounted) {
      context.push('/todo/${created.id}');
    }
  }
}

/// Narrows the directory to one label. Shell-hosted as the app bar's `bottom`,
/// which is why it carries its own [preferredSize] rather than being wrapped in
/// a `PreferredSize` at the call site.
class TodoLabelFilterBar extends ConsumerWidget implements PreferredSizeWidget {
  const TodoLabelFilterBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(46);

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
                labelStyle: chipLabelStyleOn(
                  parseHexColor(label.color),
                  selected: selected == label.id,
                ),
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
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    // The label colour is the user's pick and
                                    // sits directly behind this text, so the
                                    // foreground has to follow it.
                                    color: onColor(
                                      parseHexColor(label.color) ??
                                          scheme.surfaceContainerHighest,
                                    ),
                                  ),
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
