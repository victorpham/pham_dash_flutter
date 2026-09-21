import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How many optimistic writes are still waiting on the server, how many have
/// given up, and when the last one landed.
///
/// Optimistic writes make the screen move before the server has answered,
/// which is the point - but it also means the screen no longer says whether a
/// tap has *arrived*. This is the one fact the app bar needs to say so:
/// something is still on its way, or the last thing sent has just been
/// confirmed.
///
/// [PendingWrites.failed] is for writes that outlive their screen. A todo item
/// that fails rolls back and toasts where the user is looking, so it is not
/// counted here. A person created from the People list and left saving while
/// the user moves on has nowhere to toast when it fails ten seconds later; the
/// queue behind it (`PendingCreates`) keeps the record as "failed" and reports
/// the count here so the glyph can turn red wherever the user is.
final pendingWritesProvider =
    NotifierProvider<PendingWritesNotifier, PendingWrites>(
      PendingWritesNotifier.new,
    );

class PendingWrites {
  const PendingWrites({this.inFlight = 0, this.failed = 0, this.lastSettledAt});

  final int inFlight;

  /// Writes kept on screen as "couldn't save", awaiting a retry or a discard.
  final int failed;

  /// When the most recent write completed successfully, or null if none has.
  final DateTime? lastSettledAt;

  bool get isSyncing => inFlight > 0;
  bool get hasFailures => failed > 0;

  PendingWrites _with({int? inFlight, int? failed, DateTime? lastSettledAt}) =>
      PendingWrites(
        inFlight: inFlight ?? this.inFlight,
        failed: failed ?? this.failed,
        lastSettledAt: lastSettledAt ?? this.lastSettledAt,
      );
}

class PendingWritesNotifier extends Notifier<PendingWrites> {
  @override
  PendingWrites build() => const PendingWrites();

  /// Runs [write] and counts it in and out. Rethrows whatever it throws.
  Future<R> track<R>(Future<R> Function() write) async {
    state = state._with(inFlight: state.inFlight + 1);
    try {
      final result = await write();
      state = state._with(
        inFlight: state.inFlight - 1,
        lastSettledAt: DateTime.now(),
      );
      return result;
    } catch (_) {
      state = state._with(inFlight: state.inFlight - 1);
      rethrow;
    }
  }

  /// Sets the failed count outright. The owner of the failed records is the
  /// one source of truth for how many there are, so it reports the total
  /// rather than incrementing and decrementing around each retry.
  void setFailed(int count) {
    if (count == state.failed) return;
    state = state._with(failed: count);
  }
}
