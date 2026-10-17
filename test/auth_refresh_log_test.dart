import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_exception.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/core/cache/cache_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "I have to sign in again every day" was unanswerable, because the reason
/// the IdP gave for refusing a refresh was thrown away the moment `_refresh`
/// turned it into null. These pin down that every outcome is now recorded -
/// with Entra's AADSTS text - and that the record survives a restart.
void main() {
  late CacheLog log;
  late _MemoryStorage storage;

  setUp(() {
    log = CacheLog();
    storage = _MemoryStorage();
  });

  /// A restored session whose ID token has already lapsed, so the first
  /// [AuthService.idToken] call goes straight to the refresh.
  Future<AuthService> restored(
    _FakeAppAuth appAuth, {
    bool withRefresh = true,
  }) async {
    storage.values['phamdash_id_token'] = _jwt(
      expiresIn: const Duration(hours: -1),
    );
    if (withRefresh) storage.values['phamdash_refresh_token'] = 'rt-1';
    final auth = AuthService(appAuth: appAuth, storage: storage, log: log);
    await auth.restore();
    return auth;
  }

  CacheEvent latest(CacheEventKind kind) =>
      log.events.firstWhere((e) => e.kind == kind);

  test('a refusal records the error code and the AADSTS description', () async {
    final auth = await restored(
      _FakeAppAuth.throwing(
        FlutterAppAuthPlatformException(
          code: 'token_failed',
          platformErrorDetails: FlutterAppAuthPlatformErrorDetails(
            error: FlutterAppAuthOAuthError.invalidGrant,
            errorDescription:
                'AADSTS700084: The refresh token was issued to a '
                'single page app (SPA).\r\nTrace ID: abc\r\nCorrelation ID: def',
          ),
        ),
      ),
    );

    expect(await auth.idToken(), isNull);
    final detail = latest(CacheEventKind.authRefreshFailed).detail!;
    expect(detail, startsWith('refused: invalid_grant - AADSTS700084'));
    expect(detail, isNot(contains('Trace ID')));
    expect(detail, isNot(contains('rt-1')), reason: 'never log a token');
  });

  test('a missing refresh token is recorded as such', () async {
    final auth = await restored(_FakeAppAuth.unused(), withRefresh: false);

    expect(await auth.idToken(), isNull);
    expect(
      latest(CacheEventKind.authRestore).detail,
      startsWith('refresh token: NONE'),
    );
    expect(
      latest(CacheEventKind.authRefreshFailed).detail,
      'no refresh token stored',
    );
  });

  test('an unreachable IdP is recorded and still throws', () async {
    final auth = await restored(_FakeAppAuth.throwing(Exception('no route')));

    await expectLater(auth.idToken(), throwsA(isA<NetworkException>()));
    expect(
      latest(CacheEventKind.authRefreshFailed).detail,
      startsWith('unreachable:'),
    );
  });

  test('a successful renewal says whether the refresh token rotated', () async {
    final fresh = _jwt(expiresIn: const Duration(hours: 1));
    final auth = await restored(_FakeAppAuth.returning(fresh, 'rt-2'));

    expect(await auth.idToken(), fresh);
    expect(
      latest(CacheEventKind.authRefresh).detail,
      startsWith('refresh token rotated'),
    );
    expect(storage.values['phamdash_refresh_token'], 'rt-2');
  });

  test('the auth history survives a restart; cache chatter does not', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    log.keepAuthHistoryIn(prefs);
    log.record(CacheEventKind.miss, 'people');
    log.record(CacheEventKind.authRefreshFailed, '*', detail: 'refused: x');
    await Future<void>.delayed(Duration.zero);

    final next = CacheLog()..keepAuthHistoryIn(prefs);
    expect(next.events, isEmpty);
    expect(next.authHistory.map((e) => e.detail), ['refused: x']);
  });

  test('an unreadable stored history is ignored', () async {
    SharedPreferences.setMockInitialValues({
      CacheLog.authHistoryKey: jsonEncode([
        {'kind': 'notAKind', 'at': '2026-01-01T00:00:00Z'},
        {'kind': 'authRefresh', 'at': 'yesterday'},
        {'kind': 'authSignIn', 'key': '*', 'at': '2026-01-01T00:00:00Z'},
      ]),
    });
    final prefs = await SharedPreferences.getInstance();

    final restoredLog = CacheLog()..keepAuthHistoryIn(prefs);
    expect(restoredLog.authHistory.map((e) => e.kind), [
      CacheEventKind.authSignIn,
    ]);

    SharedPreferences.setMockInitialValues({CacheLog.authHistoryKey: '{nope'});
    expect(
      (CacheLog()..keepAuthHistoryIn(await SharedPreferences.getInstance()))
          .authHistory,
      isEmpty,
    );
  });
}

String _jwt({required Duration expiresIn}) {
  String part(Map<String, Object> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp = DateTime.now().add(expiresIn).millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'none'})}.${part({'oid': 'user-1', 'exp': exp})}.sig';
}

class _FakeAppAuth extends FlutterAppAuth {
  _FakeAppAuth.throwing(this._error) : _response = null;
  _FakeAppAuth.returning(String idToken, String refreshToken)
    : _error = null,
      _response = TokenResponse(
        null,
        refreshToken,
        null,
        idToken,
        'Bearer',
        null,
        null,
      );
  _FakeAppAuth.unused()
    : _error = StateError('should not be called'),
      _response = null;

  final Object? _error;
  final TokenResponse? _response;

  @override
  Future<TokenResponse> token(TokenRequest request) async {
    if (_error case final error?) throw error;
    return _response!;
  }
}

class _MemoryStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}
