import 'dart:async';
import 'dart:convert';

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
import 'package:pham_dash_flutter/core/ui/async_view.dart';
import 'package:pham_dash_flutter/data/models/converters.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/data/repositories/people_repository.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';
import 'package:pham_dash_flutter/features/people/person_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The person page's Relationships and Notes sections, seeded from the bulk
/// caches while the person's own fetch waits on the database.
///
/// Notes are matched by their category pill rather than their content: the
/// content renders through a Markdown widget, the pill is a plain `Text`.

const _ada = Person(id: 'aB3xQ', firstName: 'Ada', lastName: 'Lovelace');

const _adaNote = Note(
  noteId: 1,
  personId: 'aB3xQ',
  content: 'Loves the analytical engine.',
  category: 'Hobbies',
);
const _someoneElsesNote = Note(
  noteId: 2,
  personId: 'zY9wP',
  content: 'Not about Ada at all.',
  category: 'Elsewhere',
);
const _freshNote = Note(
  noteId: 3,
  personId: 'aB3xQ',
  content: 'Written since the cache was saved.',
  category: 'Fresh',
);

const _adaToByron = Relationship(
  relationshipId: 10,
  personId: 'aB3xQ',
  relatedPersonId: 'zY9wP',
  type: RelationshipType.parent,
  relatedPersonFirstName: 'Byron',
  relatedPersonLastName: 'Lovelace',
);
const _byronToAda = Relationship(
  relationshipId: 11,
  personId: 'zY9wP',
  relatedPersonId: 'aB3xQ',
  type: RelationshipType.child,
  relatedPersonFirstName: 'Ada',
  relatedPersonLastName: 'Lovelace',
);

/// Byron's own parent: Ada's grandparent, derived from the bulk table.
const _byronToAugusta = Relationship(
  relationshipId: 12,
  personId: 'zY9wP',
  relatedPersonId: 'gR4nD',
  type: RelationshipType.parent,
  relatedPersonFirstName: 'Augusta',
  relatedPersonLastName: 'Milbanke',
);

/// Subclasses rather than implements - see `todo_lists_tab_test.dart`.
class _FakeNotes extends NotesRepository {
  _FakeNotes(super.api);

  /// The person's own fetch waits on this - the database asleep.
  Completer<void>? gate;
  Object? failOwnWith;
  Object? failAllWith;
  List<Note> own = const [_adaNote];
  List<Note> everyone = const [_adaNote, _someoneElsesNote];

  @override
  Future<List<Note>> forPerson(String personId) async {
    await gate?.future;
    if (failOwnWith case final error?) throw error;
    return own;
  }

  @override
  Future<List<Note>> all() async {
    if (failAllWith case final error?) throw error;
    return everyone;
  }
}

class _FakeRelationships extends RelationshipsRepository {
  _FakeRelationships(super.api);

  Completer<void>? gate;
  Object? failOwnWith;
  Object? failAllWith;
  List<Relationship> own = const [_adaToByron];
  List<Relationship> everyone = const [_adaToByron, _byronToAda];

  @override
  Future<List<Relationship>> forPerson(String personId) async {
    await gate?.future;
    if (failOwnWith case final error?) throw error;
    return own;
  }

  @override
  Future<List<Relationship>> all() async {
    if (failAllWith case final error?) throw error;
    return everyone;
  }
}

/// The bulk caches as a previous launch would have left them.
Storage<String, String> _seededStore() {
  final store = Storage<String, String>.inMemory();
  store.write(
    'notes',
    jsonEncode([_adaNote.toJson(), _someoneElsesNote.toJson()]),
    const StorageOptions(),
  );
  store.write(
    'relationships',
    jsonEncode([_adaToByron.toJson(), _byronToAda.toJson()]),
    const StorageOptions(),
  );
  return store;
}

Future<({_FakeNotes notes, _FakeRelationships relationships})> _pumpDetail(
  WidgetTester tester, {
  Storage<String, String>? storage,
  Completer<void>? gate,
  Object? failOwnWith,
  Object? failAllWith,
  List<Note>? everyoneNotes,
  List<Relationship>? everyoneRelationships,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final notes = _FakeNotes(ApiClient(AuthService()))
    ..gate = gate
    ..failOwnWith = failOwnWith
    ..failAllWith = failAllWith;
  if (everyoneNotes != null) notes.everyone = everyoneNotes;
  final relationships = _FakeRelationships(ApiClient(AuthService()))
    ..gate = gate
    ..failOwnWith = failOwnWith
    ..failAllWith = failAllWith;
  if (everyoneRelationships != null) {
    relationships.everyone = everyoneRelationships;
  }

  final router = GoRouter(
    initialLocation: '/people/${_ada.id}',
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
      // A failing bulk fetch must not be retried on a timer under test.
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        cacheStorageProvider.overrideWithValue(storage ?? Storage.inMemory()),
        notesRepositoryProvider.overrideWithValue(notes),
        relationshipsRepositoryProvider.overrideWithValue(relationships),
        allPeopleProvider.overrideWithBuild((ref, _) => [_ada]),
        personTagsProvider.overrideWithBuild((ref, _) => const <PersonTag>[]),
        personProvider.overrideWith((ref, id) => _ada),
        personPicturesProvider.overrideWithBuild(
          (ref, _) => const <PersonPicture>[],
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  return (notes: notes, relationships: relationships);
}

void main() {
  testWidgets('sections render this person\'s slice of the bulk caches '
      'while the own fetch is pending', (tester) async {
    final gate = Completer<void>();
    await _pumpDetail(tester, storage: _seededStore(), gate: gate);
    await tester.pump();

    expect(find.text('Hobbies'), findsOneWidget);
    expect(find.text('Elsewhere'), findsNothing);
    expect(find.text('Byron Lovelace'), findsOneWidget);
    // Byron's row points back at Ada; it must not show on Ada's page. (The
    // page title and header carry her name, so look for a relationship row.)
    expect(find.widgetWithText(ListTile, 'Ada Lovelace'), findsNothing);
    // No indicator of their own - the header strip covers the wait.
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('the own fetch replaces the slice when it lands',
      (tester) async {
    final gate = Completer<void>();
    final fakes = await _pumpDetail(tester, storage: _seededStore(), gate: gate);
    fakes.notes.own = const [_freshNote, _adaNote];
    await tester.pump();
    expect(find.text('Fresh'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Fresh'), findsOneWidget);
    expect(find.text('Hobbies'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('a failed own fetch keeps the slice under a couldn\'t-refresh '
      'line', (tester) async {
    await _pumpDetail(
      tester,
      storage: _seededStore(),
      failOwnWith: const NetworkException('offline'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hobbies'), findsOneWidget);
    expect(find.text('Byron Lovelace'), findsOneWidget);
    expect(find.text(RefreshFailedBanner.title), findsNWidgets(2));
    expect(find.text('offline'), findsNothing);
    expect(find.byType(ErrorStateView), findsNothing);
  });

  testWidgets('with nothing cached the sections stay blank, then show own data, '
      'and a failing bulk endpoint is never surfaced', (tester) async {
    final gate = Completer<void>();
    await _pumpDetail(
      tester,
      gate: gate,
      // The API that predates the bulk endpoints.
      failAllWith: const ApiException(404, 'Not Found'),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Hobbies'), findsNothing);
    expect(find.text('Not Found'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Hobbies'), findsOneWidget);
    expect(find.text('Byron Lovelace'), findsOneWidget);
    expect(find.text('Not Found'), findsNothing);
  });

  testWidgets('a saved bulk copy still seeds the page when its refresh fails',
      (tester) async {
    final gate = Completer<void>();
    await _pumpDetail(
      tester,
      storage: _seededStore(),
      gate: gate,
      failAllWith: const ApiException(404, 'Not Found'),
    );
    // Let the bulk fetches fail; the own fetches are still gated.
    await tester.pump();
    await tester.pump();

    expect(find.text('Hobbies'), findsOneWidget);
    expect(find.text('Byron Lovelace'), findsOneWidget);
    expect(find.text('Not Found'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('an empty slice is an empty state, not a spinner',
      (tester) async {
    final store = Storage<String, String>.inMemory();
    store.write(
      'notes',
      jsonEncode([_someoneElsesNote.toJson()]),
      const StorageOptions(),
    );
    final gate = Completer<void>();
    // The bulk fetch is not gated, so it must agree with the seed or it would
    // hand Ada a note before the assertion.
    await _pumpDetail(
      tester,
      storage: store,
      gate: gate,
      everyoneNotes: const [_someoneElsesNote],
    );
    await tester.pump();

    expect(find.text('No notes yet. Add one above.'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('a parent\'s own parent shows as a grandparent, after the '
      'parent and without a Remove button', (tester) async {
    await _pumpDetail(
      tester,
      everyoneRelationships: const [_adaToByron, _byronToAda, _byronToAugusta],
    );
    await tester.pumpAndSettle();

    expect(find.text('OTHER RELATIONSHIPS (2)'), findsOneWidget);
    final byron = find.widgetWithText(ListTile, 'Byron Lovelace');
    final augusta = find.widgetWithText(ListTile, 'Augusta Milbanke');
    expect(byron, findsOneWidget);
    expect(augusta, findsOneWidget);
    expect(find.text('Grandparent'), findsOneWidget);
    expect(
      tester.getTopLeft(byron).dy,
      lessThan(tester.getTopLeft(augusta).dy),
    );
    // The direct row can be removed; the derived one is Byron's link.
    expect(
      find.descendant(of: byron, matching: find.byIcon(Icons.link_off)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: augusta, matching: find.byIcon(Icons.link_off)),
      findsNothing,
    );
  });
}
