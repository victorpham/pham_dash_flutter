import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// "Updated 3 min ago" - when what is on screen was last confirmed against
/// the server. Ticks over on its own so a phone left open does not keep
/// saying "just now".
///
/// A caption, not a badge: it is the answer to "is this current?", asked
/// after the refresh strip has come and gone and a saved list looks the same
/// as a fresh one.
class FreshnessCaption extends StatefulWidget {
  const FreshnessCaption({super.key, required this.updatedAt});

  /// Null renders nothing - the screen has never fetched here.
  final DateTime? updatedAt;

  /// Older than this and the caption is styled as a warning rather than a
  /// footnote: an hour is the database's own idle-to-pause window, so a list
  /// this old has not been confirmed since before the server last slept.
  static const Duration staleAfter = Duration(hours: 1);

  @override
  State<FreshnessCaption> createState() => _FreshnessCaptionState();
}

class _FreshnessCaptionState extends State<FreshnessCaption> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final at = widget.updatedAt;
    if (at == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final stale = now.difference(at) > FreshnessCaption.staleAfter;
    final scheme = Theme.of(context).colorScheme;
    final color = stale ? scheme.tertiary : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            stale ? Icons.history : Icons.check_circle_outline,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            'Updated ${formatFreshness(at, now)}',
            key: const ValueKey('freshness-caption'),
            style: TextStyle(fontSize: 11.5, color: color),
          ),
        ],
      ),
    );
  }
}

/// "just now", "3 min ago", "at 10:42", "yesterday 18:02", "12 Sep 18:02".
String formatFreshness(DateTime at, DateTime now) {
  final age = now.difference(at);
  if (age < const Duration(minutes: 1)) return 'just now';
  if (age < const Duration(hours: 1)) return '${age.inMinutes} min ago';

  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final time = DateFormat.Hm().format(at);
  if (day == today) return 'at $time';
  if (day == today.subtract(const Duration(days: 1))) return 'yesterday $time';
  return '${DateFormat.MMMd().format(at)} $time';
}
