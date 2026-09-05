import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/ui/async_view.dart';
import '../../data/models/todo_models.dart';
import 'confetti_burst.dart';
import 'scheduled_lists_controller.dart';
import 'time_status.dart';

/// "What should I be doing right now" — the dashboard's Lists tab.
///
/// Mirrors `ScheduledListsWidget.vue`.
class ScheduledListsTab extends ConsumerWidget {
  const ScheduledListsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(scheduledListsControllerProvider);
    final controller = ref.read(scheduledListsControllerProvider.notifier);

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: AsyncView<ScheduledFeed>(
        value: feed,
        onRetry: controller.refresh,
        isEmpty: (data) =>
            data.sections.active.isEmpty && data.sections.upNext == null,
        emptyIcon: Icons.task_alt,
        emptyTitle: 'Nothing scheduled right now',
        emptyMessage: 'Lists appear here around the time they are due.',
        builder: (data) {
          final sections = data.sections;

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (sections.active.isNotEmpty) ...[
                const _SectionLabel('Active'),
                for (final list in sections.active)
                  ScheduledListCard(list: list, feed: data),
              ],
              if (sections.upNext != null) ...[
                const _SectionLabel('Up next'),
                ScheduledListCard(
                  list: sections.upNext!,
                  feed: data,
                  preview: true,
                ),
              ],
              if (data.dismissed.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: TextButton.icon(
                    onPressed: controller.restoreDismissed,
                    icon: const Icon(Icons.undo, size: 18),
                    label: Text(
                      'Show ${data.dismissed.length} dismissed',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
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

class ScheduledListCard extends ConsumerWidget {
  const ScheduledListCard({
    super.key,
    required this.list,
    required this.feed,
    this.preview = false,
  });

  final TodoList list;
  final ScheduledFeed feed;

  /// The "Up next" card is a preview: it shows the schedule but not the
  /// checklist, since it is not actionable yet.
  final bool preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(scheduledListsControllerProvider.notifier);
    final status = ScheduledListRules.statusFor(list, feed.now);
    final stripe = parseHexColor(list.color);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => context.push('/todo/${list.id}'),
                            child: Text(
                              list.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        _StatusPill(status: status),
                        if (!preview) ...[
                          IconButton(
                            tooltip: 'Reset items',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.refresh, size: 18),
                            onPressed: () => controller.resetItems(list.id),
                          ),
                          IconButton(
                            tooltip: 'Done for today',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.check_circle_outline,
                                size: 18),
                            onPressed: () => controller.dismiss(list.id),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            scheduleContext(list),
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.mutedForeground,
                            ),
                          ),
                        ),
                        Text(
                          '${list.completedItems}/${list.totalItems} done',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!preview) ...[
                    const SizedBox(height: 4),
                    // Ungrouped items first, then each group under its name —
                    // the same split the API returns them in.
                    for (final item in feed.ordered(list.id, list.items))
                      ChecklistRow(
                        item: item,
                        onToggle: (position) =>
                            _toggle(context, controller, item, position),
                      ),
                    for (final group in list.groups) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
                        child: Text(
                          group.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.mutedForeground,
                          ),
                        ),
                      ),
                      for (final item in feed.ordered(list.id, group.items))
                        ChecklistRow(
                          item: item,
                          onToggle: (position) =>
                              _toggle(context, controller, item, position),
                        ),
                    ],
                    const SizedBox(height: 6),
                  ] else
                    const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(
    BuildContext context,
    ScheduledListsController controller,
    TodoItem item,
    Offset position,
  ) {
    // Celebrate completions only, not un-completions.
    if (!item.isCompleted) fireConfettiAt(context, position);
    controller.toggleItem(list.id, item);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final TimeStatus status;

  @override
  Widget build(BuildContext context) {
    if (status.label.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final color = switch (status.tone) {
      StatusTone.now => scheme.primary,
      StatusTone.upcoming => const Color(0xFF3B82F6),
      StatusTone.started => const Color(0xFFF59E0B),
      StatusTone.past => scheme.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// A checklist row with a deliberately large tap target — these get tapped in
/// passing, often one-handed.
class ChecklistRow extends StatelessWidget {
  const ChecklistRow({
    super.key,
    required this.item,
    required this.onToggle,
  });

  final TodoItem item;

  /// Receives the global position of the checkbox, so the confetti can be
  /// anchored where the tap landed.
  final void Function(Offset position) onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconKey = GlobalKey();

    return InkWell(
      onTap: () {
        final box = iconKey.currentContext?.findRenderObject() as RenderBox?;
        final position = box == null
            ? Offset.zero
            : box.localToGlobal(box.size.center(Offset.zero));
        onToggle(position);
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(12 + item.indentLevel * 18.0, 8, 12, 8),
        child: Row(
          children: [
            Icon(
              key: iconKey,
              item.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 26,
              color: item.isCompleted ? scheme.completed : scheme.outline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.content,
                style: TextStyle(
                  fontSize: 14.5,
                  color: item.isCompleted
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface,
                  decoration:
                      item.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
