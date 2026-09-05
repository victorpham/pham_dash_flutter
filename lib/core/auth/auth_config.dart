import 'package:flutter_appauth/flutter_appauth.dart';

/// Microsoft Entra External ID (CIAM) configuration.
///
/// One app registration is shared by the web, Kotlin and Flutter clients.
class AuthConfig {
  const AuthConfig._();

  static const String clientId = 'f1d49195-c6f9-436a-a281-dc2ff4aa72e3';
  static const String tenantId = 'db995a66-edcb-4c60-a7b7-60a061d2c149';

  /// The friendly tenant host, matching `authConfig.js` (Vue) and
  /// `msal_config.json` (Kotlin). Sign-in **must** happen on this host.
  ///
  /// Entra derives its federation callback to the upstream identity providers
  /// from whichever host the browser is on, and only this host's callbacks are
  /// registered upstream:
  ///   Google:    https://phamdashauth.ciamlogin.com/common/federation/oidc
  ///   Microsoft: https://phamdashauth.ciamlogin.com/common/federation/oauth2msa
  /// Authenticating on the tenant-GUID host instead produces a GUID-host
  /// callback, which Google rejects with `redirect_uri_mismatch` before the
  /// user ever gets back to us. See
  /// `PhamDash/Instructions/azure-entra-external-id-setup.md`.
  static const String _authority = 'https://phamdashauth.ciamlogin.com/$tenantId';

  /// Endpoints are pinned rather than discovered, and this is load-bearing.
  ///
  /// This host's discovery document advertises an `issuer` on the *GUID* host
  /// (`https://$tenantId.ciamlogin.com/$tenantId/v2.0`). AppAuth validates that
  /// the issuer matches the document it fetched, so pointing `issuer:` at the
  /// friendly host fails that check. Supplying the configuration directly skips
  /// discovery, and with it the issuer comparison — which is safe here because
  /// both hosts mint tokens carrying that same GUID-host issuer, the one the
  /// API is configured to accept.
  static const AuthorizationServiceConfiguration serviceConfiguration =
      AuthorizationServiceConfiguration(
    authorizationEndpoint: '$_authority/oauth2/v2.0/authorize',
    tokenEndpoint: '$_authority/oauth2/v2.0/token',
    endSessionEndpoint: '$_authority/oauth2/v2.0/logout',
  );

  /// Must be registered in the app registration under
  /// Authentication -> Mobile and desktop applications. The scheme half also
  /// appears in `android/app/build.gradle.kts` (appAuthRedirectScheme) and in
  /// the iOS `Info.plist` (CFBundleURLSchemes).
  static const String redirectUrl = 'com.phamdash.app://oauthredirect';

  /// `offline_access` is what earns us a refresh token, which the 401
  /// refresh-and-retry rule depends on. The web client omits it and relies on
  /// MSAL's hidden-iframe renewal, which has no mobile equivalent.
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
  ];

  /// Refresh this long before the token's `exp` rather than waiting for a 401.
  static const Duration refreshLeeway = Duration(minutes: 2);
}
