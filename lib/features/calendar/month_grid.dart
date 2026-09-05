import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/api/api_date.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/calendar_models.dart';
import 'event_utils.dart';

/// Cell metrics. Everything from [_dateRowHeight] down is read by the widgets
/// below *and* by the pill-fit arithmetic in [_PillCapacity], so the two stay in
/// step — a cell that renders taller than the arithmetic assumed overflows.
const double _cellAspectRatio = 0.62;
const double _cellPaddingV = 3;
const double _dateRowHeight = 20;
const double _dateRowGap = 2;
const double _pillPaddingV = 1;
const double _pillGap = 1.5;
const double _morePaddingTop = 1;

/// Both styles pin `height` so a line box is `fontSize * height` whatever the
/// font resolves to, and neither inherits a line height from the theme — the
/// fit arithmetic below has to predict these exactly.
const TextStyle _pillTextStyle = TextStyle(fontSize: 8.5, height: 1.2);
const TextStyle _moreTextStyle = TextStyle(fontSize: 8.5, height: 1.2);

/// Laid-out height of a single line in [style], honouring the viewer's text
/// scale. Measured rather than derived from `fontSize * height`: the font's own
/// metrics and pixel rounding both move the result, and guessing it low is
/// exactly what overflows the cell.
double _lineHeight(TextStyle style, TextScaler scaler) {
  final painter = TextPainter(
    text: TextSpan(text: 'Ag', style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  return painter.height;
}

/// Laid-out heights of the two rows a cell stacks, measured once per grid.
class _PillMetrics {
  const _PillMetrics({required this.pill, required this.more});

  /// [base] is the ambient [DefaultTextStyle], which the cells' `Text` widgets
  /// merge under their own styles — measuring without it would measure a
  /// different style than the one that renders.
  factory _PillMetrics.measure({
    required TextStyle base,
    required TextScaler scaler,
  }) => _PillMetrics(
    pill:
        _lineHeight(base.merge(_pillTextStyle), scaler) +
        _pillPaddingV * 2 +
        _pillGap,
    more: _lineHeight(base.merge(_moreTextStyle), scaler) + _morePaddingTop,
  );

  /// One event pill, including its padding and the gap below it.
  final double pill;

  /// The "+N more" line, including its top padding.
  final double more;
}

/// How many event pills actually fit in one day cell.
///
/// [withoutMore] applies when every event is shown; [withMore] leaves room for
/// the trailing "+N more" line, so a truncated cell drops one further pill to
/// pay for it.
class _PillCapacity {
  /// [availableHeight] is the cell's real content height, taken from its own
  /// constraints. Deriving it from the grid's width and aspect ratio instead
  /// lands within a pixel of the truth, and a pixel is all it takes to overflow.
  factory _PillCapacity.fit({
    required double availableHeight,
    required _PillMetrics metrics,
    required int limit,
  }) {
    final available = availableHeight - _dateRowHeight - _dateRowGap;

    int fitting(double budget) =>
        budget <= 0 ? 0 : math.min((budget / metrics.pill).floor(), limit);

    return _PillCapacity._(
      withoutMore: fitting(available),
      withMore: fitting(available - metrics.more),
      canShowMore: available >= metrics.more,
    );
  }

  const _PillCapacity._({
    required this.withoutMore,
    required this.withMore,
    required this.canShowMore,
  });

  final int withoutMore;
  final int withMore;

  /// False only in a cell too short for even the overflow line, where the
  /// honest choice is to show one more pill instead of a count nothing follows.
  final bool canShowMore;

  /// The pills to render for a day holding [total] events.
  int visibleFor(int total) => total <= withoutMore || !canShowMore
      ? math.min(total, withoutMore)
      : withMore;
}

/// A month grid: seven columns, up to six rows, each cell showing the date and
/// a few coloured event pills with a "+N more" overflow.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.events,
    required this.onDayTap,
    this.maxPillsPerDay = 5,
  });

  /// Any date within the month to render.
  final DateTime month;
  final List<CalendarEvent> events;
  final void Function(DateTime day, List<CalendarEvent> events) onDayTap;
  final int maxPillsPerDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final byDay = EventUtils.groupByDay(events);
    final today = ApiDate.startOfDay(DateTime.now());

    final firstOfMonth = DateTime(month.year, month.month);
    // Grid starts on the Sunday on or before the 1st, matching the web layout.
    final leading = firstOfMonth.weekday % 7;
    final gridStart = firstOfMonth.subtract(Duration(days: leading));

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cellCount = ((leading + daysInMonth) / 7).ceil() * 7;

    return Column(
      children: [
        Row(
          children: [
            for (final label in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Expanded(
          // Text metrics are the same for every cell, so they are measured once
          // here; each cell then fits them to its own height.
          child: Builder(
            builder: (context) {
              final metrics = _PillMetrics.measure(
                base: DefaultTextStyle.of(context).style,
                scaler: MediaQuery.textScalerOf(context),
              );

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: _cellAspectRatio,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                ),
                itemCount: cellCount,
                itemBuilder: (context, index) {
                  final day = gridStart.add(Duration(days: index));
                  final inMonth = day.month == month.month;
                  final dayEvents = byDay[ApiDate.startOfDay(day)] ?? const [];
                  final isToday = ApiDate.isSameDay(day, today);
                  final isWeekend =
                      day.weekday == DateTime.saturday ||
                      day.weekday == DateTime.sunday;

                  return _DayCell(
                    day: day,
                    events: dayEvents,
                    inMonth: inMonth,
                    isToday: isToday,
                    isWeekend: isWeekend,
                    metrics: metrics,
                    maxPills: maxPillsPerDay,
                    onTap: dayEvents.isEmpty
                        ? null
                        : () => onDayTap(day, dayEvents),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.events,
    required this.inMonth,
    required this.isToday,
    required this.isWeekend,
    required this.metrics,
    required this.maxPills,
    required this.onTap,
  });

  final DateTime day;
  final List<CalendarEvent> events;
  final bool inMonth;
  final bool isToday;
  final bool isWeekend;
  final _PillMetrics metrics;
  final int maxPills;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? scheme.primary.withValues(alpha: 0.07)
              : (!inMonth || isWeekend)
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
              : null,
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
            right: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: _cellPaddingV,
        ),
        // The cell's own constraints are the only reliable height budget, so
        // the pill count is decided here rather than guessed from the grid.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final capacity = _PillCapacity.fit(
              availableHeight: constraints.maxHeight,
              metrics: metrics,
              limit: maxPills,
            );
            final visible = events
                .take(capacity.visibleFor(events.length))
                .toList();
            final overflow = events.length - visible.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Today's date number sits in a filled circle.
                Center(
                  child: Container(
                    width: _dateRowHeight,
                    height: _dateRowHeight,
                    alignment: Alignment.center,
                    decoration: isToday
                        ? BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isToday
                            ? scheme.onPrimary
                            : inMonth
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: _dateRowGap),
                for (final event in visible) _EventPill(event: event),
                if (overflow > 0 && capacity.canShowMore)
                  Padding(
                    padding: const EdgeInsets.only(top: _morePaddingTop),
                    child: Text(
                      '+$overflow more',
                      // Single line, always: in a cell this narrow the label wraps
                      // in some fonts, and a second line is height the fit
                      // arithmetic never budgeted for.
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _moreTextStyle.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EventPill extends StatelessWidget {
  const _EventPill({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = parseHexColor(event.accentColorHex) ?? scheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: _pillGap),
      padding: const EdgeInsets.symmetric(
        horizontal: 3,
        vertical: _pillPaddingV,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        event.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _pillTextStyle.copyWith(color: scheme.onSurface),
      ),
    );
  }
}
