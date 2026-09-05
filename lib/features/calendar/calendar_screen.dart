import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_date.dart';
import '../../core/providers.dart';
import '../../core/ui/async_view.dart';
import '../../data/models/calendar_models.dart';
import '../schedule/schedule_tab.dart';
import 'calendar_grid_tab.dart';
import 'event_detail_sheet.dart';
import 'event_utils.dart';
import 'month_grid.dart';
import 'week_grid.dart';

/// The four view modes the web calendar page offers.
enum CalendarView { today, week, month, grid }

final calendarViewProvider = valueProvider<CalendarView>(
  () => CalendarView.today,
);

final calendarAnchorProvider = valueProvider<DateTime>(
  () => ApiDate.startOfDay(DateTime.now()),
);

/// The range for the current view, computed the same way the web page does.
({DateTime from, DateTime to}) _rangeFor(CalendarView view, DateTime anchor) {
  final start = ApiDate.startOfDay(anchor);
  return switch (view) {
    CalendarView.today => (from: start, to: start.add(const Duration(days: 1))),
    // A rolling seven days from the current date, not a calendar week.
    CalendarView.week => (from: start, to: start.add(const Duration(days: 7))),
    CalendarView.month || CalendarView.grid => (
        from: DateTime(anchor.year, anchor.month - 1, 20),
        to: DateTime(anchor.year, anchor.month + 2, 10),
      ),
  };
}

final calendarEventsProvider =
    FutureProvider.autoDispose<List<CalendarEvent>>((ref) async {
  final view = ref.watch(calendarViewProvider);
  final anchor = ref.watch(calendarAnchorProvider);
  final hideTu = ref.watch(hideTuMeetingsProvider);
  final range = _rangeFor(view, anchor);

  final events = await ref.watch(calendarRepositoryProvider).events(
        timeMin: range.from,
        timeMax: range.to,
        maxResults: 100,
      );
  return EventUtils.hideTuMeetings(events, hide: hideTu);
});

final syncStatusProvider = FutureProvider.autoDispose<CalendarSyncStatus>(
  (ref) => ref.watch(calendarRepositoryProvider).syncStatus(),
);

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(calendarViewProvider);
    final anchor = ref.watch(calendarAnchorProvider);
    final events = ref.watch(calendarEventsProvider);
    final hideTu = ref.watch(hideTuMeetingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: hideTu ? 'Show Tu meetings' : 'Hide Tu meetings',
            icon: Icon(hideTu ? Icons.filter_alt : Icons.filter_alt_off),
            onPressed: () => ref
                .read(hideTuMeetingsProvider.notifier)
                .value = !hideTu,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: _CalendarHeader(view: view, anchor: anchor),
        ),
      ),
      body: RefreshIndicator(
        // Pull-to-refresh forces a sync rather than just re-reading: the server
        // only re-syncs Google every 15 minutes on its own.
        onRefresh: () => _forceSync(ref),
        child: AsyncView<List<CalendarEvent>>(
          value: events,
          onRetry: () => ref.invalidate(calendarEventsProvider),
          isEmpty: (data) =>
              data.isEmpty && view != CalendarView.grid,
          emptyIcon: Icons.event_available_outlined,
          emptyTitle: 'Nothing scheduled',
          emptyMessage: 'No events in this range.',
          builder: (data) => switch (view) {
            CalendarView.grid => MonthGrid(
                month: anchor,
                events: data,
                onDayTap: (day, dayEvents) => showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      for (final event in dayEvents) EventRow(event: event),
                    ],
                  ),
                ),
              ),
            CalendarView.week => WeekGrid(
                weekStart: anchor,
                events: data,
                onEventTap: (event) => showEventDetailSheet(context, event),
              ),
            CalendarView.today || CalendarView.month => _EventListView(
                events: data,
              ),
          },
        ),
      ),
    );
  }

  Future<void> _forceSync(WidgetRef ref) async {
    try {
      await ref.read(calendarRepositoryProvider).sync();
    } finally {
      ref.invalidate(calendarEventsProvider);
      ref.invalidate(syncStatusProvider);
    }
  }
}

class _EventListView extends StatelessWidget {
  const _EventListView({required this.events});

  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    final grouped = EventUtils.groupByDay(events);

    return CustomScrollView(
      slivers: [
        for (final entry in grouped.entries) ...[
          SliverStickyHeader(label: EventUtils.dateHeader(entry.key)),
          SliverList.builder(
            itemCount: entry.value.length,
            itemBuilder: (context, index) =>
                EventRow(event: entry.value[index]),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _CalendarHeader extends ConsumerWidget {
  const _CalendarHeader({required this.view, required this.anchor});

  final CalendarView view;
  final DateTime anchor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final sync = ref.watch(syncStatusProvider).value;
    final lastSynced = sync?.lastSyncedAt;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SegmentedButton<CalendarView>(
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: CalendarView.today, label: Text('Today')),
              ButtonSegment(value: CalendarView.week, label: Text('Week')),
              ButtonSegment(value: CalendarView.month, label: Text('Month')),
              ButtonSegment(value: CalendarView.grid, label: Text('Grid')),
            ],
            selected: {view},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => ref
                .read(calendarViewProvider.notifier)
                .value = selection.first,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _step(ref, -1),
            ),
            TextButton(
              onPressed: () => ref
                  .read(calendarAnchorProvider.notifier)
                  .value = ApiDate.startOfDay(DateTime.now()),
              child: const Text('Today'),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _step(ref, 1),
            ),
            Expanded(
              child: Text(
                _label(),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                lastSynced == null
                    ? 'Not synced'
                    : 'Synced ${EventUtils.relative(lastSynced)}',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _label() => switch (view) {
        CalendarView.today => DateFormat('EEEE, MMM d').format(anchor),
        CalendarView.week =>
          '${DateFormat('MMM d').format(anchor)} – ${DateFormat('MMM d').format(anchor.add(const Duration(days: 6)))}',
        CalendarView.month ||
        CalendarView.grid =>
          DateFormat('MMMM yyyy').format(anchor),
      };

  /// Prev/next moves by the unit the current view is built around.
  void _step(WidgetRef ref, int direction) {
    final current = ref.read(calendarAnchorProvider);
    final next = switch (view) {
      CalendarView.today => current.add(Duration(days: direction)),
      CalendarView.week => current.add(Duration(days: 7 * direction)),
      CalendarView.month ||
      CalendarView.grid =>
        DateTime(current.year, current.month + direction, 1),
    };
    ref.read(calendarAnchorProvider.notifier).value = next;
  }
}
