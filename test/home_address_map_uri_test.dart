import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/features/people/home_address.dart';

const _address = '123 Main St, Austin, TX 78701';

void main() {
  // The point of geo: over a maps.google.com URL — ACTION_VIEW leaves the
  // choice of app with the user, which is what "open in my map app" means.
  test('Android gets a geo: search rather than a vendor URL', () {
    expect(
      mapSearchUri(_address, platform: TargetPlatform.android).toString(),
      'geo:0,0?q=123%20Main%20St%2C%20Austin%2C%20TX%2078701',
    );
  });

  test('iOS gets the Apple Maps link, since geo: is unhandled there', () {
    expect(
      mapSearchUri('123 Main St', platform: TargetPlatform.iOS).toString(),
      'https://maps.apple.com/?q=123%20Main%20St',
    );
  });

  // Uri's own query encoder writes `+` for a space and Android's geo parser is
  // unreliable about that, so the encoding has to stay percent-based.
  test('spaces are percent-encoded, never plus-encoded', () {
    final uri = mapSearchUri('a b', platform: TargetPlatform.android);

    expect(uri.toString(), contains('%20'));
    expect(uri.toString(), isNot(contains('+')));
  });

  test('surrounding whitespace is dropped', () {
    expect(
      mapSearchUri('  $_address  ', platform: TargetPlatform.android),
      mapSearchUri(_address, platform: TargetPlatform.android),
    );
  });
}
