import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pham_dash_flutter/app/router.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';
import 'package:pham_dash_flutter/features/people/person_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _address = '123 Main St, Austin, TX 78701';

const _urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

Person _person({String? homeAddress}) => Person(
      id: 'aB3xQ',
      firstName: 'Ha',
      lastName: 'Pham',
      homeAddress: homeAddress,
    );

/// Every other section is overridden empty, so nothing but the header is under
/// test and nothing reaches the network. Mirrors `person_detail_tags_test.dart`
/// — this project duplicates the harness per file rather than sharing it.
Future<void> _pumpDetail(WidgetTester tester, Person person) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final router = GoRouter(
    initialLocation: '/people/${person.id}',
    routes: [
      GoRoute(
        path: '/people/:id',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          name: personPageName,
          child: PersonDetailScreen(personId: state.pathParameters['id']!),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        allPeopleProvider.overrideWithBuild((ref, _) => [person]),
        personTagsProvider.overrideWithBuild((ref, _) => const <PersonTag>[]),
        personProvider.overrideWith((ref, id) => person),
        personRelationshipsProvider.overrideWith(
          (ref, id) => const <Relationship>[],
        ),
        personNotesProvider.overrideWith((ref, id) => const <Note>[]),
        personPicturesProvider.overrideWith(
          (ref, id) => const <PersonPicture>[],
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

/// A holder rather than a returned value: the handler fires long after the
/// mock is installed, so the test has to read the field, not a copy of it.
class _Clipboard {
  String? text;
}

/// `Clipboard.setData` is a method call on `SystemChannels.platform`, which has
/// no implementation in a test — so it has to be mocked to be observed at all.
/// Answering null for everything else on that channel is what the real platform
/// effectively does for the calls this screen makes.
_Clipboard _mockClipboard(WidgetTester tester) {
  final board = _Clipboard();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        board.text = (call.arguments as Map)['text'] as String?;
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return board;
}

class _Launches {
  String? url;
}

_Launches _mockUrlLauncher(WidgetTester tester, {bool succeeds = true}) {
  final launches = _Launches();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _urlLauncherChannel,
    (call) async {
      // `launch`, not `launchUrl`: UrlLauncherPlatform.launchUrl has a default
      // implementation that funnels down to the older `launch` channel method,
      // and MethodChannelUrlLauncher only implements that one.
      if (call.method == 'launch') {
        launches.url = (call.arguments as Map)['url'] as String?;
        return succeeds;
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlLauncherChannel, null),
  );
  return launches;
}

void main() {
  testWidgets('a person with no address shows no address row', (tester) async {
    await _pumpDetail(tester, _person());

    expect(find.byIcon(Icons.place_outlined), findsNothing);
    expect(find.byIcon(Icons.map_outlined), findsNothing);
  });

  // The web writes through a trimmed input, and anything else talking to the
  // API could store "". Blank has to read as absent or the header draws an
  // empty line with two affordances hanging off it.
  testWidgets('a blank address counts as no address', (tester) async {
    await _pumpDetail(tester, _person(homeAddress: '   '));

    expect(find.byIcon(Icons.place_outlined), findsNothing);
    expect(find.byIcon(Icons.map_outlined), findsNothing);
  });

  testWidgets('an address is shown when there is one', (tester) async {
    await _pumpDetail(tester, _person(homeAddress: _address));

    expect(find.text(_address), findsOneWidget);
    expect(find.byIcon(Icons.place_outlined), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
  });

  testWidgets('tapping the address copies it', (tester) async {
    final board = _mockClipboard(tester);
    await _pumpDetail(tester, _person(homeAddress: _address));

    await tester.tap(find.text(_address));
    await tester.pumpAndSettle();

    expect(board.text, _address);
    expect(find.text('Address copied'), findsOneWidget);
  });

  // No platform override needed: flutter_test already reports Android, which
  // is the branch mapSearchUri takes for geo:.
  testWidgets('the map button hands the address to a map app', (tester) async {
    final launches = _mockUrlLauncher(tester);
    await _pumpDetail(tester, _person(homeAddress: _address));

    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    expect(launches.url, startsWith('geo:0,0?q='));
    expect(launches.url, contains('123%20Main%20St'));
  });

  // launchUrl returns false rather than throwing when nothing can handle the
  // intent, so the failure is easy to swallow silently.
  testWidgets('a phone with no map app is told so', (tester) async {
    _mockUrlLauncher(tester, succeeds: false);
    await _pumpDetail(tester, _person(homeAddress: _address));

    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    expect(find.text('No app on this phone can open a map.'), findsOneWidget);
  });
}
