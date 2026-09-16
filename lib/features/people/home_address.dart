import 'package:flutter/foundation.dart';

/// A search URI for [address] that opens whatever map app the user prefers.
///
/// **Android** gets the `geo:` scheme with the `q` extension. It resolves
/// through `ACTION_VIEW`, so the user's own default map app wins — or the system
/// chooser, when several are installed and none is default. A
/// `maps.google.com` URL would quietly force one vendor, which is not what
/// "open in my map app" means. `0,0` is the conventional placeholder origin for
/// a query with no coordinates, and requires the `geo` entry in the manifest's
/// `<queries>` block to be visible to `canLaunchUrl` on Android 11+.
///
/// **Everywhere else** — iOS in practice — gets Apple's universal link, because
/// iOS does not handle `geo:` at all. It must be launched with
/// `LaunchMode.externalApplication`: `platformDefault` sends https URLs to an
/// in-app Safari view on iOS, which would show the Maps *web page* rather than
/// handing off to the app.
///
/// [Uri.encodeComponent] rather than `Uri`'s own query encoder, which emits `+`
/// for a space — Android's geo parser is unreliable about that.
///
/// [platform] is injectable so this can be tested on either branch; reading
/// `Platform.isAndroid` instead would just report the machine running the test.
Uri mapSearchUri(String address, {TargetPlatform? platform}) {
  final encoded = Uri.encodeComponent(address.trim());
  return (platform ?? defaultTargetPlatform) == TargetPlatform.android
      ? Uri.parse('geo:0,0?q=$encoded')
      : Uri.parse('https://maps.apple.com/?q=$encoded');
}
