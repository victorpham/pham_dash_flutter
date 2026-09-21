import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/pending_writes.dart';

/// App-bar glyph for optimistic writes: a cloud with a spinner while any are
/// in flight, a check for a moment once the last one lands, a red cloud while
/// any have failed and are waiting on a retry, nothing otherwise.
///
/// In flight outranks failed: something is still happening, and the failure
/// is still on screen where it happened. Tapping the failed glyph calls
/// [onFailedTap] - the people screens open their failed-changes sheet - and
/// without one the glyph is a tooltip only, which is still enough to say why
/// it is red.
///
/// Sized like an `IconButton` so it sits in an `AppBar.actions` row without
/// shifting its neighbours when it appears.
class SyncIndicator extends ConsumerStatefulWidget {
  const SyncIndicator({super.key, this.onFailedTap});

  final VoidCallback? onFailedTap;

  /// How long the check stays up after the last write is confirmed.
  static const Duration confirmedFor = Duration(seconds: 2);

  @override
  ConsumerState<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends ConsumerState<SyncIndicator> {
  Timer? _hide;
  bool _showConfirmed = false;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _confirmed() {
    _hide?.cancel();
    setState(() => _showConfirmed = true);
    _hide = Timer(SyncIndicator.confirmedFor, () {
      if (mounted) setState(() => _showConfirmed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingWritesProvider, (previous, next) {
      // The check is for a write that just landed - not for an app that
      // simply has none in flight.
      if (previous != null &&
          previous.inFlight > 0 &&
          next.inFlight == 0 &&
          next.lastSettledAt != previous.lastSettledAt) {
        _confirmed();
      }
    });
    final pending = ref.watch(pendingWritesProvider);
    final scheme = Theme.of(context).colorScheme;

    final Widget? glyph;
    if (pending.isSyncing) {
      glyph = Tooltip(
        key: const ValueKey('sync-in-flight'),
        message: pending.inFlight == 1
            ? 'Saving 1 change…'
            : 'Saving ${pending.inFlight} changes…',
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, color: scheme.onSurfaceVariant),
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: scheme.primary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    } else if (pending.hasFailures) {
      final message = pending.failed == 1
          ? '1 change couldn’t be saved'
          : '${pending.failed} changes couldn’t be saved';
      final onTap = widget.onFailedTap;
      glyph = onTap == null
          ? Tooltip(
              key: const ValueKey('sync-failed'),
              message: message,
              child: Icon(Icons.cloud_off_outlined, color: scheme.error),
            )
          : IconButton(
              key: const ValueKey('sync-failed'),
              tooltip: message,
              icon: Icon(Icons.cloud_off_outlined, color: scheme.error),
              onPressed: onTap,
            );
    } else if (_showConfirmed) {
      glyph = Tooltip(
        key: const ValueKey('sync-confirmed'),
        message: 'Saved',
        child: Icon(Icons.cloud_done_outlined, color: scheme.primary),
      );
    } else {
      glyph = null;
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: glyph == null ? const SizedBox.shrink() : Center(child: glyph),
      ),
    );
  }
}
