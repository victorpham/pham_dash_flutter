import 'package:flutter/material.dart';

import '../../core/api/api_date.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/calendar_models.dart';
import 'event_layout.dart';

/// A seven-day time grid: an hour gutter beside seven day columns, with events
/// positioned by time and overlapping events split into side-by-side lanes.
class WeekGrid extends StatelessWidget {
  const WeekGrid({
    super.key,
    required this.weekStart,
    required this.events,
    required this.onEventTap,
  });

  /// The first day shown; six more follow it.
  final DateTime weekStart;
  final List<CalendarEvent> events;
  final void Function(CalendarEvent event) onEventTap;

  static const double _gutterWidth = 34;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = [
      for (var i = 0; i < 7; i++) ApiDate.startOfDay(weekStart).add(Duration(days: i)),
    ];
    final today = ApiDate.startOfDay(DateTime.now());

    return Column(
      children: [
        // Day-of-week header, aligned past the hour gutter.
        Row(
          children: [
            const SizedBox(width: _gutterWidth),
            for (final day in days)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Text(
                        const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                            [day.weekday % 7],
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ApiDate.isSameDay(day, today)
                              ? scheme.primary
                              : scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: EventLayout.dayHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HourGutter(),
                  for (final day in days)
                    Expanded(
                      child: _DayColumn(
                        day: day,
                        events: events,
                        onEventTap: onEventTap,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HourGutter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: WeekGrid._gutterWidth,
      child: Stack(
        children: [
          for (final marker in EventLayout.hourMarkers)
            Positioned(
              top: marker.offset - 6,
              right: 4,
              child: Text(
                marker.label,
                style: TextStyle(
                  fontSize: 9,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.events,
    required this.onEventTap,
  });

  final DateTime day;
  final List<CalendarEvent> events;
  final void Function(CalendarEvent event) onEventTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final positioned = EventLayout.layout(events, day);
    final now = DateTime.now();
    final nowOffset =
        ApiDate.isSameDay(day, now) ? EventLayout.currentTimeOffset(now) : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return Stack(
            children: [
              // Dashed-looking hour lines.
              for (final marker in EventLayout.hourMarkers)
                Positioned(
                  top: marker.offset,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.28),
                  ),
                ),

              for (final placed in positioned)
                Positioned(
                  top: placed.top,
                  height: placed.height,
                  left: (width / placed.totalColumns) * placed.column,
                  width: width / placed.totalColumns,
                  child: _EventBlock(
                    positioned: placed,
                    onTap: () => onEventTap(placed.event),
                  ),
                ),

              if (nowOffset != null)
                Positioned(
                  top: nowOffset,
                  left: 0,
                  right: 0,
                  child: Container(height: 1.5, color: scheme.error),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EventBlock extends StatelessWidget {
  const _EventBlock({required this.positioned, required this.onTap});

  final PositionedEvent positioned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color =
        parseHexColor(positioned.event.accentColorHex) ?? scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 1, bottom: 1),
      child: Material(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 2)),
            ),
            child: Text(
              positioned.event.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                height: 1.15,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
