import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_date.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/person_avatar.dart';
import '../../data/models/calendar_models.dart';
import '../calendar/event_detail_sheet.dart';
import '../calendar/event_utils.dart';

/// The next seven days of events, grouped under sticky date headers.
///
/// Mirrors `CalendarEventsWidget.vue`.
final upcomingEventsProvider =
    FutureProvider.autoDispose<List<CalendarEvent>>((ref) async {
  final now = DateTime.now();
  final events = await ref.watch(calendarRepositoryProvider).events(
        timeMin: ApiDate.startOfDay(now),
        timeMax: ApiDate.startOfDay(now).add(const Duration(days: 7)),
        maxResults: 20,
      );
  return EventUtils.hideTuMeetings(events);
});

class ScheduleTab extends ConsumerWidget {
  const ScheduleTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(upcomingEventsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(upcomingEventsProvider.future),
      child: AsyncView<List<CalendarEvent>>(
        value: events,
        onRetry: () => ref.invalidate(upcomingEventsProvider),
        emptyIcon: Icons.event_available_outlined,
        emptyTitle: 'Your week looks clear!',
        emptyMessage: 'Nothing scheduled in the next seven days.',
        builder: (data) => _EventList(events: data),
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({required this.events});

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

/// A pinned date header. `SliverPersistentHeader` with `pinned: true` gives the
/// sticky behaviour the web headers have.
class SliverStickyHeader extends StatelessWidget {
  const SliverStickyHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyHeaderDelegate(label: label),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({required this.label});

  final String label;

  @override
  double get minExtent => 38;

  @override
  double get maxExtent => 38;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) =>
      oldDelegate.label != label;
}

/// One event row: a 4px accent stripe, title, time, location and up to two
/// attendee avatars.
class EventRow extends StatelessWidget {
  const EventRow({super.key, required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = parseHexColor(event.accentColorHex) ?? scheme.primary;
    final location = event.location;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        color: scheme.rowSurface,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showEventDetailSheet(context, event),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 13,
                              color: scheme.mutedForeground,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              EventUtils.timeRange(event),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                        if (location != null && location.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.place_outlined,
                                size: 13,
                                color: scheme.mutedForeground,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: scheme.mutedForeground,
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
                if (event.attendees.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: AttendeeAvatarGroup(attendees: event.attendees),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Up to two overlapping avatars plus a "+N" badge, as in the web widget.
class AttendeeAvatarGroup extends StatelessWidget {
  const AttendeeAvatarGroup({
    super.key,
    required this.attendees,
    this.maxVisible = 2,
    this.size = 26,
  });

  final List<EventAttendeeRef> attendees;
  final int maxVisible;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = attendees.take(maxVisible).toList();
    final overflow = attendees.length - visible.length;
    final overlap = size * 0.32;

    return SizedBox(
      height: size,
      width: size + (visible.length - 1 + (overflow > 0 ? 1 : 0)) * (size - overlap),
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 1.5),
                ),
                child: PersonAvatar(
                  storedPath: visible[i].profilePictureUrl,
                  initials: _initials(visible[i].name),
                  size: size,
                ),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * (size - overlap),
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceContainerHighest,
                  border: Border.all(color: scheme.surface, width: 1.5),
                ),
                child: Text(
                  '+$overflow',
                  style: TextStyle(
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
