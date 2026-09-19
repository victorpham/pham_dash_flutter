import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How many optimistic writes are still waiting on the server, and when the
/// last one landed.
///
/// Optimistic writes make the screen move before the server has answered,
/// which is the point - but it also means the screen no longer says whether a
/// tap has *arrived*. This is the one fact the app bar needs to say so:
/// something is still on its way, or the last thing sent has just been
/// confirmed. Failures are not recorded here; the row rolls back and toasts,
/// which is already louder than an icon.
final pendingWritesProvider =
    NotifierProvider<PendingWritesNotifier, PendingWrites>(
      PendingWritesNotifier.new,
    );

class PendingWrites {
  const PendingWrites({this.inFlight = 0, this.lastSettledAt});

  final int inFlight;

  /// When the most recent write completed successfully, or null if none has.
  final DateTime? lastSettledAt;

  bool get isSyncing => inFlight > 0;
}

class PendingWritesNotifier extends Notifier<PendingWrites> {
  @override
  PendingWrites build() => const PendingWrites();

  /// Runs [write] and counts it in and out. Rethrows whatever it throws.
  Future<R> track<R>(Future<R> Function() write) async {
    state = PendingWrites(
      inFlight: state.inFlight + 1,
      lastSettledAt: state.lastSettledAt,
    );
    try {
      final result = await write();
      state = PendingWrites(
        inFlight: state.inFlight - 1,
        lastSettledAt: DateTime.now(),
      );
      return result;
    } catch (_) {
      state = PendingWrites(
        inFlight: state.inFlight - 1,
        lastSettledAt: state.lastSettledAt,
      );
      rethrow;
    }
  }
}
