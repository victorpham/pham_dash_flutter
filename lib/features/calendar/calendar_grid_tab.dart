import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_date.dart';
import '../../core/providers.dart';
import '../../core/ui/async_view.dart';
import '../../data/models/calendar_models.dart';
import '../schedule/schedule_tab.dart';
import 'event_detail_sheet.dart';
import 'event_utils.dart';
import 'month_grid.dart';
import 'week_grid.dart';

enum GridMode { month, week }

/// The anchor date the grid is showing, moved by the prev/next buttons.
final gridAnchorProvider = valueProvider<DateTime>(
  () => ApiDate.startOfDay(DateTime.now()),
);

final gridModeProvider = valueProvider<GridMode>(() => GridMode.month);

/// Persisted per session; the web exposes the same toggle on its calendar page.
final hideTuMeetingsProvider = valueProvider<bool>(() => true);

/// Events for whatever range the grid currently shows.
final gridEventsProvider =
    FutureProvider.autoDispose<List<CalendarEvent>>((ref) async {
  final anchor = ref.watch(gridAnchorProvider);
  final mode = ref.watch(gridModeProvider);
  final hideTu = ref.watch(hideTuMeetingsProvider);

  final (from, to) = switch (mode) {
    // A month grid spills into the adjacent months, so fetch a little either
    // side rather than leaving the leading and trailing cells empty.
    GridMode.month => (
        DateTime(anchor.year, anchor.month - 1, 20),
        DateTime(anchor.year, anchor.month + 2, 10),
      ),
    GridMode.week => (
        _weekStart(anchor),
        _weekStart(anchor).add(const Duration(days: 7)),
      ),
  };

  final events = await ref
      .watch(calendarRepositoryProvider)
      .events(timeMin: from, timeMax: to, maxResults: 250);

  return EventUtils.hideTuMeetings(events, hide: hideTu);
});

DateTime _weekStart(DateTime day) =>
    ApiDate.startOfDay(day).subtract(Duration(days: day.weekday % 7));

/// The dashboard's Calendar tab — a month grid with a week alternative.
///
/// Mirrors `CalendarGridWidget.vue`.
class CalendarGridTab extends ConsumerWidget {
  const CalendarGridTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anchor = ref.watch(gridAnchorProvider);
    final mode = ref.watch(gridModeProvider);
    final events = ref.watch(gridEventsProvider);

    return Column(
      children: [
        _GridHeader(anchor: anchor, mode: mode),
        const Divider(height: 1),
        Expanded(
          child: AsyncView<List<CalendarEvent>>(
            value: events,
            onRetry: () => ref.invalidate(gridEventsProvider),
            // An empty month is a legitimate state, not an empty-state screen —
            // the grid itself still needs to be shown.
            isEmpty: (_) => false,
            builder: (data) => switch (mode) {
              GridMode.month => MonthGrid(
                  month: anchor,
                  events: data,
                  onDayTap: (day, dayEvents) =>
                      _showDaySheet(context, day, dayEvents),
                ),
              GridMode.week => WeekGrid(
                  weekStart: _weekStart(anchor),
                  events: data,
                  onEventTap: (event) => showEventDetailSheet(context, event),
                ),
            },
          ),
        ),
      ],
    );
  }

  void _showDaySheet(
    BuildContext context,
    DateTime day,
    List<CalendarEvent> events,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              DateFormat('EEEE, MMMM d').format(day),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (final event in events) EventRow(event: event),
        ],
      ),
    );
  }
}

class _GridHeader extends ConsumerWidget {
  const _GridHeader({required this.anchor, required this.mode});

  final DateTime anchor;
  final GridMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideTu = ref.watch(hideTuMeetingsProvider);

    final label = mode == GridMode.month
        ? DateFormat('MMMM yyyy').format(anchor)
        : '${DateFormat('MMM d').format(_weekStart(anchor))} – '
            '${DateFormat('MMM d').format(_weekStart(anchor).add(const Duration(days: 6)))}';

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _step(ref, -1),
            ),
            TextButton(
              onPressed: () => ref.read(gridAnchorProvider.notifier).value =
                  ApiDate.startOfDay(DateTime.now()),
              child: const Text('Today'),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _step(ref, 1),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            SegmentedButton<GridMode>(
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: const [
                ButtonSegment(
                  value: GridMode.month,
                  icon: Icon(Icons.calendar_view_month, size: 18),
                ),
                ButtonSegment(
                  value: GridMode.week,
                  icon: Icon(Icons.calendar_view_week, size: 18),
                ),
              ],
              selected: {mode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  ref.read(gridModeProvider.notifier).value = selection.first,
            ),
            IconButton(
              tooltip: 'Open full calendar',
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: () => context.push('/calendar'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            children: [
              Checkbox(
                value: hideTu,
                visualDensity: VisualDensity.compact,
                onChanged: (value) => ref
                    .read(hideTuMeetingsProvider.notifier)
                    .value = value ?? true,
              ),
              const Text('Hide Tu meetings', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
      ],
    );
  }

  void _step(WidgetRef ref, int direction) {
    final current = ref.read(gridAnchorProvider);
    ref.read(gridAnchorProvider.notifier).value = mode == GridMode.month
        ? DateTime(current.year, current.month + direction, 1)
        : current.add(Duration(days: 7 * direction));
  }
}
