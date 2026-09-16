import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/api/api_exception.dart';
import 'package:pham_dash_flutter/core/api/server_warmup.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/data/models/preference_models.dart';
import 'package:pham_dash_flutter/data/repositories/people_repository.dart';

/// Subclasses rather than implements: the repository holds a private
/// `ApiClient`. Only `get` is overridden, so the client is never touched.
class _FakePreferences extends UserPreferenceRepository {
  _FakePreferences(super.api);

  int calls = 0;
  Object? failWith;
  Completer<UserPreference>? pending;

  @override
  Future<UserPreference> get() {
    calls++;
    final error = failWith;
    if (error != null) return Future.error(error);
    return pending?.future ?? Future.value(const UserPreference());
  }
}

void main() {
  late _FakePreferences prefs;
  late DateTime now;
  late ServerWarmup warmup;

  setUp(() {
    prefs = _FakePreferences(ApiClient(AuthService()));
    now = DateTime(2026, 9, 15, 8);
    warmup = ServerWarmup(prefs, now: () => now);
  });

  // Foreground flips arrive in bursts; a database that answered a moment ago
  // has not paused, so a second ping inside the window is just spend.
  test('pings once per window', () async {
    await warmup.ping();
    await warmup.ping();
    expect(prefs.calls, 1);

    now = now.add(ServerWarmup.window);
    await warmup.ping();
    expect(prefs.calls, 2);
  });

  // The ping is exactly the request that hangs for tens of seconds while the
  // database resumes; a resume-during-resume must not stack a second one.
  test('a ping in flight is shared, not repeated', () async {
    prefs.pending = Completer();
    final first = warmup.ping();
    final second = warmup.ping();
    expect(prefs.calls, 1);

    prefs.pending!.complete(const UserPreference());
    await first;
    await second;
  });

  // The warm-up is invisible; whatever went wrong, the real request will
  // report it better than an unhandled error from a lifecycle callback.
  test('never throws', () async {
    prefs.failWith = const NetworkException('offline');
    await expectLater(warmup.ping(), completes);
  });
}
