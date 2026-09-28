import 'dart:async';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_exception.dart';
import 'auth_config.dart';
import 'jwt.dart';

/// The signed-in user, as read out of the ID token.
class AuthUser {
  const AuthUser({required this.id, this.displayName, this.email});

  /// The Entra `oid` claim. Every user-scoped row in the API is keyed on this.
  final String id;
  final String? displayName;
  final String? email;
}

class _StoredTokens {
  const _StoredTokens({required this.idToken, this.refreshToken});

  final String idToken;
  final String? refreshToken;

  DateTime? get expiresAt => Jwt.expiry(idToken);

  bool get isFresh {
    final exp = expiresAt;
    if (exp == null) return false;
    return DateTime.now().toUtc().isBefore(exp.subtract(AuthConfig.refreshLeeway));
  }
}

/// Owns the OIDC flow and the token cache.
///
/// **The API expects the ID token as the bearer, not the access token.** The
/// API sets `AllowWebApiToBeAuthorizedByACL = true`, so it validates issuer,
/// audience and lifetime but requires no scope or role claim — an access token
/// minted for Graph would simply be rejected. The Vue client does the same
/// thing behind a confusingly-named `getAccessToken()`; the naming here is
/// deliberately literal.
class AuthService {
  AuthService({FlutterAppAuth? appAuth, FlutterSecureStorage? storage})
      : _appAuth = appAuth ?? const FlutterAppAuth(),
        _storage = storage ?? const FlutterSecureStorage();

  static const _idTokenKey = 'phamdash_id_token';
  static const _refreshTokenKey = 'phamdash_refresh_token';

  final FlutterAppAuth _appAuth;
  final FlutterSecureStorage _storage;

  _StoredTokens? _tokens;

  /// Shared across concurrent callers so a burst of parallel requests that all
  /// see an expired token triggers exactly one refresh, not one each.
  Future<String?>? _refreshInFlight;

  final _userController = StreamController<AuthUser?>.broadcast();

  /// Emits on sign-in and sign-out. The router listens to this to redirect.
  Stream<AuthUser?> get userChanges => _userController.stream;

  AuthUser? get currentUser {
    final token = _tokens?.idToken;
    if (token == null) return null;
    final id = Jwt.userId(token);
    if (id == null) return null;
    return AuthUser(
      id: id,
      displayName: Jwt.displayName(token),
      email: Jwt.email(token),
    );
  }

  bool get isSignedIn => _tokens != null;

  /// Loads any persisted session. Call once at startup.
  ///
  /// A stored token that has already expired is kept rather than discarded — the
  /// refresh token outlives it, so [idToken] can still recover the session
  /// silently. Only a failed refresh signs the user out.
  Future<AuthUser?> restore() async {
    final idToken = await _storage.read(key: _idTokenKey);
    if (idToken == null) return null;
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    _tokens = _StoredTokens(idToken: idToken, refreshToken: refreshToken);

    final user = currentUser;
    if (user == null) {
      // Unreadable token — treat as no session at all.
      await _clear();
      return null;
    }
    _userController.add(user);
    return user;
  }

  Future<AuthUser> signIn() async {
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        AuthConfig.clientId,
        AuthConfig.redirectUrl,
        serviceConfiguration: AuthConfig.serviceConfiguration,
        scopes: AuthConfig.scopes,
        promptValues: const ['select_account'],
      ),
    );

    final idToken = result.idToken;
    if (idToken == null) {
      throw StateError(
        'Sign-in returned no ID token. The API authenticates with the ID '
        'token, so there is nothing usable to send.',
      );
    }

    await _persist(idToken: idToken, refreshToken: result.refreshToken);
    final user = currentUser;
    if (user == null) {
      throw StateError('ID token carried no oid/sub claim to identify the user.');
    }
    _userController.add(user);
    return user;
  }

  /// Returns a usable ID token, refreshing when it is stale or when
  /// [forceRefresh] is set (the 401 retry path).
  ///
  /// Returns null when there is no recoverable session; the caller should treat
  /// that as signed out. **Throws [NetworkException] when the refresh could not
  /// be attempted** - see [_refresh] for why the two are not the same answer.
  Future<String?> idToken({bool forceRefresh = false}) async {
    final tokens = _tokens;
    if (tokens == null) return null;
    if (!forceRefresh && tokens.isFresh) return tokens.idToken;

    return _refreshInFlight ??= _refresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  /// The OAuth 2.0 error codes that mean the authorization server answered and
  /// refused. Anything else - no connectivity, DNS, a timeout, the browser
  /// component failing to start - never got an answer at all.
  static const Set<String> _rejections = {
    FlutterAppAuthOAuthError.invalidGrant,
    FlutterAppAuthOAuthError.invalidClient,
    FlutterAppAuthOAuthError.unauthorizedClient,
    FlutterAppAuthOAuthError.invalidRequest,
    FlutterAppAuthOAuthError.invalidScope,
    FlutterAppAuthOAuthError.unsupportedGrantType,
  };

  /// Renews the ID token, telling a refusal apart from a failure to ask.
  ///
  /// Null means the session is genuinely over: there is nothing to renew with,
  /// or the IdP rejected what we had. A [NetworkException] means we never
  /// reached it and the session may well still be good.
  ///
  /// The distinction is load-bearing, and it used to be missing: a bare
  /// `catch (_) { return null; }` here made a dropped connection look exactly
  /// like a revoked refresh token, `ApiClient` signed the user out over it, and
  /// the sign-out took the whole offline cache with it - at the one moment, a
  /// flaky network with the database asleep, when the cache is what the app has
  /// left. See `PreferencesStorage.claimFor`, which is the other half of that
  /// fix.
  Future<String?> _refresh() async {
    final refreshToken = _tokens?.refreshToken;
    if (refreshToken == null) {
      // Nothing to renew with; the caller decides whether to sign out.
      return null;
    }

    try {
      final result = await _appAuth.token(
        TokenRequest(
          AuthConfig.clientId,
          AuthConfig.redirectUrl,
          serviceConfiguration: AuthConfig.serviceConfiguration,
          scopes: AuthConfig.scopes,
          refreshToken: refreshToken,
        ),
      );
      final idToken = result.idToken;
      if (idToken == null) return null;

      // A refresh response may omit refresh_token, meaning "keep using the one
      // you have"; only overwrite when a new one is actually issued.
      await _persist(
        idToken: idToken,
        refreshToken: result.refreshToken ?? refreshToken,
      );
      return idToken;
    } on FlutterAppAuthPlatformException catch (error) {
      if (_rejections.contains(error.platformErrorDetails.error)) return null;
      throw const NetworkException(_unreachable);
    } on Object {
      throw const NetworkException(_unreachable);
    }
  }

  static const String _unreachable =
      'Could not reach the sign-in service. Check your connection and try '
      'again.';

  Future<void> signOut() async {
    final idToken = _tokens?.idToken;
    await _clear();
    _userController.add(null);

    if (idToken == null) return;
    try {
      await _appAuth.endSession(
        EndSessionRequest(
          idTokenHint: idToken,
          serviceConfiguration: AuthConfig.serviceConfiguration,
          postLogoutRedirectUrl: AuthConfig.redirectUrl,
        ),
      );
    } catch (_) {
      // The local session is already gone; a failed or cancelled browser
      // round trip must not leave the app stuck in a signed-in state.
    }
  }

  Future<void> _persist({required String idToken, String? refreshToken}) async {
    _tokens = _StoredTokens(idToken: idToken, refreshToken: refreshToken);
    await _storage.write(key: _idTokenKey, value: idToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> _clear() async {
    _tokens = null;
    await _storage.delete(key: _idTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  void dispose() => _userController.close();
}
