import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'pending_creates.dart';

/// The one-line status a pending record's row carries: a small spinner and
/// "Saving…" while the write is out, or the failure in the error colour with
/// Retry and Discard beside it. Nothing at all for a `done` entry - the row
/// is then indistinguishable from a fetched one, which is the point.
class PendingStatusLine extends ConsumerWidget {
  const PendingStatusLine({super.key, required this.entry, this.onDiscarded});

  final PendingCreate entry;

  /// Called after a discard, for a page whose subject was just dropped.
  final VoidCallback? onDiscarded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    if (entry.isSending) {
      return Row(
        key: const ValueKey('pending-saving'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: scheme.mutedForeground,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Saving…',
            style: TextStyle(fontSize: 12.5, color: scheme.mutedForeground),
          ),
        ],
      );
    }

    if (entry.isFailed) {
      final queue = ref.read(pendingCreatesProvider.notifier);
      return Wrap(
        key: const ValueKey('pending-failed'),
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Icon(Icons.error_outline, size: 14, color: scheme.error),
          Text(
            'Couldn’t save — ${entry.error?.message ?? 'something went wrong'}',
            style: TextStyle(fontSize: 12.5, color: scheme.error),
          ),
          _SmallAction('Retry', onPressed: () => queue.retry(entry.key)),
          _SmallAction(
            'Discard',
            onPressed: () {
              queue.discard(entry.key);
              onDiscarded?.call();
            },
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction(this.text, {required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
    ),
    onPressed: onPressed,
    child: Text(text),
  );
}

/// Every failed create, with Retry and Discard on each and Retry all on top.
///
/// Reached from the red `SyncIndicator`, which is the only thing that says a
/// write failed on a page the user has since left.
Future<void> showFailedChangesSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const FailedChangesSheet(),
    );

class FailedChangesSheet extends ConsumerWidget {
  const FailedChangesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final failed = ref
        .watch(pendingCreatesProvider)
        .where((e) => e.isFailed)
        .toList();
    final queue = ref.read(pendingCreatesProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  failed.isEmpty
                      ? 'Everything is saved'
                      : 'Couldn’t save ${failed.length == 1 ? '1 change' : '${failed.length} changes'}',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (failed.length > 1)
                TextButton(
                  onPressed: queue.retryAllFailed,
                  child: const Text('Retry all'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final entry in failed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.error_outline, color: scheme.error),
              title: Text(entry.label),
              subtitle: Text(
                entry.error?.message ?? 'Something went wrong.',
                style: TextStyle(color: scheme.mutedForeground),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => queue.retry(entry.key),
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: () => queue.discard(entry.key),
                    child: const Text('Discard'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
