import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/api/api_exception.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';

/// The 401 path, which used to take the whole offline cache with it.
///
/// `AuthService._refresh` caught everything and returned null, so a phone that
/// could not reach the token endpoint looked exactly like one whose refresh
/// token had been revoked. `ApiClient` signed the user out over it, and the
/// sign-out ran `PreferencesStorage.clearAll` - at the one moment, a flaky
/// network with the database asleep, when the saved copy is all the app has.
/// Now only an answer from the IdP ends the session.
void main() {
  late _Always401 adapter;

  setUp(() => adapter = _Always401());

  ApiClient clientFor(AuthService auth) {
    final dio = Dio()..httpClientAdapter = adapter;
    return ApiClient(auth, dio: dio);
  }

  test('a refresh that never reached the IdP is a network failure', () async {
    final auth = _UnreachableIdp();
    final client = clientFor(auth);
    final expirations = <void>[];
    client.sessionExpired.listen(expirations.add);

    await expectLater(
      client.get<dynamic>('/anything'),
      throwsA(isA<NetworkException>()),
    );
    await Future<void>.delayed(Duration.zero);

    expect(auth.signedOut, isFalse, reason: 'the session may still be good');
    expect(expirations, isEmpty, reason: 'nothing should clear the cache');
    expect(adapter.calls, 1, reason: 'the retry never went out');

    client.dispose();
  });

  test('a refresh the IdP refused still ends the session', () async {
    final auth = _RevokedRefreshToken();
    final client = clientFor(auth);
    final expirations = <void>[];
    client.sessionExpired.listen(expirations.add);

    await expectLater(
      client.get<dynamic>('/anything'),
      throwsA(isA<SessionExpiredException>()),
    );
    await Future<void>.delayed(Duration.zero);

    expect(auth.signedOut, isTrue);
    expect(expirations, hasLength(1));

    client.dispose();
  });

  // The request interceptor renews a stale token before the request goes out,
  // so it reaches the same fork one step earlier and must answer the same way.
  test('an offline renewal before the request never reaches the API', () async {
    final auth = _UnreachableIdp(onEveryCall: true);
    final client = clientFor(auth);

    await expectLater(
      client.get<dynamic>('/anything'),
      throwsA(isA<NetworkException>()),
    );

    expect(adapter.calls, 0);
    expect(auth.signedOut, isFalse);

    client.dispose();
  });
}

/// Answers 401 to everything, and counts how often it was asked.
class _Always401 implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString(
      '{"message":"Unauthorized"}',
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Subclassed rather than mocked, as the rest of the suite does. The real
/// constructor touches nothing, but [signOut] would reach secure storage.
abstract class _FakeAuth extends AuthService {
  bool signedOut = false;

  @override
  Future<void> signOut() async => signedOut = true;
}

/// The token endpoint could not be reached.
class _UnreachableIdp extends _FakeAuth {
  _UnreachableIdp({this.onEveryCall = false});

  /// Whether the stored token is stale enough that even the pre-flight renewal
  /// in `_onRequest` has to go out.
  final bool onEveryCall;

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    if (forceRefresh || onEveryCall) {
      throw const NetworkException('Could not reach the sign-in service.');
    }
    return 'stale-but-present';
  }
}

/// The IdP answered, and said no.
class _RevokedRefreshToken extends _FakeAuth {
  @override
  Future<String?> idToken({bool forceRefresh = false}) async =>
      forceRefresh ? null : 'stale-but-present';
}
