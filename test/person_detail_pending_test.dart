import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pham_dash_flutter/app/router.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/api/api_exception.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/converters.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/data/repositories/people_repository.dart';
import 'package:pham_dash_flutter/features/people/pending_creates.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';
import 'package:pham_dash_flutter/features/people/person_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The person page opened on a `pending-<n>` id: the placeholder straight from
/// the queue, notes queued against it, and what happens when the create lands
/// or fails.

const _byron = Person(id: 'zY9wP', firstName: 'Byron', lastName: 'Lovelace');

class _FakePeople extends PeopleRepository {
  _FakePeople(super.api);

  Completer<void>? gate;
  Object? failWith;
  final byIdCalls = <String>[];

  @override
  Future<Person?> create({
    required String firstName,
    required String lastName,
    String? vietnameseName,
    String? homeAddress,
    DateTime? birthDate,
  }) async {
    await gate?.future;
    if (failWith case final error?) throw error;
    return Person(id: 'real1', firstName: firstName, lastName: lastName);
  }

  @override
  Future<Person?> byId(String id) async {
    byIdCalls.add(id);
    return id == 'real1'
        ? const Person(id: 'real1', firstName: 'Ada', lastName: 'Lovelace')
        : null;
  }
}

class _FakeNotes extends NotesRepository {
  _FakeNotes(super.api);

  final created = <String>[];

  @override
  Future<Note?> create(
    String personId, {
    required String content,
    String? category,
  }) async {
    created.add(personId);
    return Note(noteId: 101, personId: personId, content: content);
  }

  @override
  Future<List<Note>> forPerson(String personId) async => const [];

  @override
  Future<List<Note>> all() async => const [];
}

class _FakeRelationships extends RelationshipsRepository {
  _FakeRelationships(super.api);

  @override
  Future<List<Relationship>> forPerson(String personId) async => const [];

  @override
  Future<List<Relationship>> all() async => const [];
}

class _FakeTags extends PersonTagsRepository {
  _FakeTags(super.api);

  @override
  Future<void> attach(String personId, int tagId) async {}
}

typedef _Harness = ({
  ProviderContainer container,
  GoRouter router,
  _FakePeople people,
  _FakeNotes notes,
});

Future<_Harness> _pump(WidgetTester tester) async {
  // Tall enough that header, banner, both sections and the composer are all
  // on screen at once - a ListView culls what is scrolled away.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(AuthService());
  final people = _FakePeople(api);
  final notes = _FakeNotes(api);

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      cacheStorageProvider.overrideWithValue(Storage.inMemory()),
      peopleRepositoryProvider.overrideWithValue(people),
      notesRepositoryProvider.overrideWithValue(notes),
      relationshipsRepositoryProvider.overrideWithValue(
        _FakeRelationships(api),
      ),
      personTagsRepositoryProvider.overrideWithValue(_FakeTags(api)),
      allPeopleProvider.overrideWithBuild((ref, _) => [_byron]),
      personTagsProvider.overrideWithBuild((ref, _) => const <PersonTag>[]),
      personPicturesProvider.overrideWithBuild(
        (ref, _) => const <PersonPicture>[],
      ),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
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
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  return (container: container, router: router, people: people, notes: notes);
}

Finder get _saving => find.byKey(const ValueKey('pending-saving'));
Finder get _failed => find.byKey(const ValueKey('pending-failed'));
Finder get _banner => find.byKey(const ValueKey('pending-person-banner'));

void main() {
  testWidgets('renders the queue\'s placeholder without fetching, and a note '
      'added meanwhile lands with the real id', (tester) async {
    final h = await _pump(tester);
    h.people.gate = Completer<void>();
    final placeholder = h.container
        .read(pendingCreatesProvider.notifier)
        .addPerson(firstName: 'Ada', lastName: 'Lovelace');

    h.router.push('/people/${placeholder.id}');
    // Past the page transition; a settle would wait on the status spinner.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Ada Lovelace'), findsWidgets);
    expect(_banner, findsOneWidget);
    expect(_saving, findsOneWidget);
    expect(find.byTooltip('Edit'), findsNothing);
    expect(h.people.byIdCalls, isEmpty);

    // A note typed now waits for the person; the card shows at once.
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'First note');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save note'));
    await tester.pump();

    expect(_saving, findsNWidgets(2));
    expect(h.notes.created, isEmpty);

    // The person lands: the page becomes the real one, and the note follows.
    h.people.gate!.complete();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(h.notes.created, ['real1']);
    expect(_banner, findsNothing);
    expect(_saving, findsNothing);
    expect(h.people.byIdCalls, contains('real1'));
    await tester.pump();
    expect(find.byTooltip('Edit'), findsOneWidget);
  });

  testWidgets('a failed create shows the banner as failed, and Discard leaves '
      'the page', (tester) async {
    final h = await _pump(tester);
    h.people.failWith = const NetworkException('Server asleep');
    final placeholder = h.container
        .read(pendingCreatesProvider.notifier)
        .addPerson(firstName: 'Ada', lastName: 'Lovelace');

    h.router.push('/people/${placeholder.id}');
    // Past the page transition; a settle would wait on the status spinner.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // Past the page transition; a settle would wait on the status spinner.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(_failed, findsOneWidget);
    expect(find.textContaining('Server asleep'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(h.container.read(pendingCreatesProvider), isEmpty);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('a queued relationship shows in the section with its status', (
    tester,
  ) async {
    final h = await _pump(tester);
    h.people.gate = Completer<void>();
    final queue = h.container.read(pendingCreatesProvider.notifier);
    final placeholder = queue.addPerson(firstName: 'Ada', lastName: 'Lovelace');
    queue.addRelationship(
      placeholder.id,
      related: _byron,
      type: RelationshipType.parent,
      personName: 'Ada',
    );

    h.router.push('/people/${placeholder.id}');
    // Past the page transition; a settle would wait on the status spinner.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // Past the page transition; a settle would wait on the status spinner.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.widgetWithText(ListTile, 'Byron Lovelace'), findsOneWidget);
    expect(find.text('Parent'), findsOneWidget);
    // No Remove button on a row the server does not have yet.
    expect(find.byTooltip('Remove'), findsNothing);
    // The banner's status and the row's.
    expect(_saving, findsNWidgets(2));
  });
}
