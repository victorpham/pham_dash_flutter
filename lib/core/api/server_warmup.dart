import '../../data/repositories/people_repository.dart';

/// Wakes the production database before the user asks it for anything.
///
/// Azure hosts PhamDash's SQL as a serverless database that auto-pauses after
/// an hour without a connection, and resuming it takes tens of seconds. The
/// App Service is Always On, so the API itself answers at once - it is the
/// first query behind it that hangs while `EnableRetryOnFailure` waits for the
/// database to come back. Weather never feels this because it never touches
/// the API (see `WeatherRepository`).
///
/// `GET /health` is the obvious probe and the wrong one: it is deliberately
/// dependency-free and never opens a connection, so it would wake nothing.
/// `GET /api/user-preferences` is the cheapest query the API runs - one row by
/// an indexed user id, and it never 404s - so that is the ping.
///
/// The wait is not shortened; it is moved. Firing this when the app returns
/// to the foreground lets the resume overlap the seconds the user spends
/// looking at the screen, instead of starting when they tap.
class ServerWarmup {
  ServerWarmup(this._preferences, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final UserPreferenceRepository _preferences;
  final DateTime Function() _now;

  /// Foreground flips come in bursts - a notification shade, a quick app
  /// switch - and a database that answered this recently has not paused, so
  /// one ping per window is enough.
  static const Duration window = Duration(minutes: 5);

  DateTime? _lastPing;
  Future<void>? _inFlight;

  /// Sends the ping unless one went out within [window]. Never throws: a
  /// warm-up that fails has nothing to tell the user that the real request
  /// will not say better.
  Future<void> ping() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final last = _lastPing;
    if (last != null && _now().difference(last) < window) {
      return Future.value();
    }
    _lastPing = _now();

    return _inFlight = _preferences
        .get()
        .then<void>((_) {}, onError: (Object _) {})
        .whenComplete(() => _inFlight = null);
  }
}
