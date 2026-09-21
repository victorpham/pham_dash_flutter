import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/api/api_exception.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/core/sync/pending_writes.dart';
import 'package:pham_dash_flutter/data/models/converters.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/data/repositories/people_repository.dart';
import 'package:pham_dash_flutter/features/people/pending_creates.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';

/// The queue behind "Add person", "Add note" and "Add relationship": what it
/// shows while the server is asleep, how a note waits for the person it is
/// about, and what Retry and Discard do.

const _byron = Person(id: 'zY9wP', firstName: 'Byron', lastName: 'Lovelace');

/// Subclasses rather than implements - a repository holds a private
/// `ApiClient`. Every write waits on [gate] (the database asleep) and then
/// throws [failWith] if set, so a test can hold a request open and decide
/// how it ends.
class _FakePeople extends PeopleRepository {
  _FakePeople(super.api);

  Completer<void>? gate;
  Object? failWith;
  Object? failUploadWith;
  final created = <String>[];
  final uploaded = <String>[];
  int nextId = 1;

  Future<void> _write() async {
    await gate?.future;
    if (failWith case final error?) throw error;
  }

  @override
  Future<Person?> create({
    required String firstName,
    required String lastName,
    String? vietnameseName,
    String? homeAddress,
    DateTime? birthDate,
  }) async {
    await _write();
    final id = 'real${nextId++}';
    created.add(id);
    return Person(id: id, firstName: firstName, lastName: lastName);
  }

  @override
  Future<String?> uploadProfilePicture(
    String id, {
    required String filePath,
    required String fileName,
  }) async {
    if (failUploadWith case final error?) throw error;
    uploaded.add('$id:$fileName');
    return '/uploads/$fileName';
  }
}

class _FakeTags extends PersonTagsRepository {
  _FakeTags(super.api);

  final attached = <String>[];

  @override
  Future<void> attach(String personId, int tagId) async {
    attached.add('$personId:$tagId');
  }
}

class _FakeNotes extends NotesRepository {
  _FakeNotes(super.api);

  Completer<void>? gate;
  Object? failWith;
  final created = <({String personId, String content})>[];

  @override
  Future<Note?> create(
    String personId, {
    required String content,
    String? category,
  }) async {
    await gate?.future;
    if (failWith case final error?) throw error;
    created.add((personId: personId, content: content));
    return Note(
      noteId: 100 + created.length,
      personId: personId,
      content: content,
    );
  }
}

class _FakeRelationships extends RelationshipsRepository {
  _FakeRelationships(super.api);

  Object? failWith;
  final created = <({String personId, String relatedPersonId})>[];

  @override
  Future<void> create(
    String personId, {
    required String relatedPersonId,
    required RelationshipType type,
  }) async {
    if (failWith case final error?) throw error;
    created.add((personId: personId, relatedPersonId: relatedPersonId));
  }
}

typedef _Harness = ({
  ProviderContainer container,
  PendingCreates queue,
  _FakePeople people,
  _FakeTags tags,
  _FakeNotes notes,
  _FakeRelationships relationships,
});

_Harness _harness() {
  final api = ApiClient(AuthService());
  final people = _FakePeople(api);
  final tags = _FakeTags(api);
  final notes = _FakeNotes(api);
  final relationships = _FakeRelationships(api);
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      peopleRepositoryProvider.overrideWithValue(people),
      personTagsRepositoryProvider.overrideWithValue(tags),
      notesRepositoryProvider.overrideWithValue(notes),
      relationshipsRepositoryProvider.overrideWithValue(relationships),
      personTagsProvider.overrideWithBuild(
        (ref, _) => const [PersonTag(id: 7, name: 'Family', personCount: 0)],
      ),
    ],
  );
  addTearDown(container.dispose);
  // Keep the queue alive for the test's duration, as the app's screens do.
  container.listen(pendingCreatesProvider, (_, _) {});
  return (
    container: container,
    queue: container.read(pendingCreatesProvider.notifier),
    people: people,
    tags: tags,
    notes: notes,
    relationships: relationships,
  );
}

/// Lets the queued futures run to their next await.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'a queued person is a placeholder under a pending id until it lands',
    () async {
      final h = _harness();
      h.people.gate = Completer<void>();

      final placeholder = h.queue.addPerson(
        firstName: 'Ada',
        lastName: 'Lovelace',
        tagIds: {7},
        picturePath: r'C:\tmp\ada.jpg',
        pictureName: 'ada.jpg',
      );
      await _settle();

      expect(isPendingPersonId(placeholder.id), isTrue);
      expect(placeholder.fullName, 'Ada Lovelace');
      // The ticked tag shows as a chip before the server has attached it.
      expect(placeholder.tags.single.name, 'Family');
      expect(h.queue.person(placeholder.id)?.isSending, isTrue);
      expect(h.queue.resolve(placeholder.id), placeholder.id);
      expect(h.container.read(pendingWritesProvider).inFlight, 1);
      expect(h.people.created, isEmpty);

      h.people.gate!.complete();
      await _settle();
      await _settle();

      final entry = h.queue.person(placeholder.id)!;
      expect(entry.isDone, isTrue);
      expect(entry.realId, 'real1');
      expect(h.queue.resolve(placeholder.id), 'real1');
      // Tags and the picture followed the create, against the real id.
      expect(h.tags.attached, ['real1:7']);
      expect(h.people.uploaded, ['real1:ada.jpg']);
      expect(h.container.read(pendingWritesProvider).inFlight, 0);
    },
  );

  test(
    'a failed create stays as failed, is counted, and can be retried',
    () async {
      final h = _harness();
      h.people.failWith = const NetworkException('Server asleep');

      final placeholder = h.queue.addPerson(firstName: 'Ada', lastName: 'L');
      await _settle();

      final failed = h.queue.person(placeholder.id)!;
      expect(failed.isFailed, isTrue);
      expect(failed.error?.message, 'Server asleep');
      expect(h.container.read(pendingWritesProvider).failed, 1);

      h.people.failWith = null;
      h.queue.retry(placeholder.id);
      expect(h.queue.person(placeholder.id)?.isSending, isTrue);
      expect(h.container.read(pendingWritesProvider).failed, 0);
      await _settle();

      expect(h.queue.person(placeholder.id)?.isDone, isTrue);
      expect(h.people.created, ['real1']);
    },
  );

  test('a retry after the create landed but the upload failed does not '
      'create the person twice', () async {
    final h = _harness();
    h.people.failUploadWith = const ApiException(400, 'Too big');

    final placeholder = h.queue.addPerson(
      firstName: 'Ada',
      lastName: 'L',
      picturePath: '/tmp/a.jpg',
    );
    await _settle();

    final failed = h.queue.person(placeholder.id)!;
    expect(failed.isFailed, isTrue);
    // The id is known even though the entry failed...
    expect(failed.realId, 'real1');
    expect(h.queue.resolve(placeholder.id), 'real1');

    h.people.failUploadWith = null;
    h.queue.retry(placeholder.id);
    await _settle();

    // ...so the retry only redoes the upload.
    expect(h.people.created, ['real1']);
    expect(h.people.uploaded, ['real1:a.jpg']);
    expect(h.queue.person(placeholder.id)?.isDone, isTrue);
  });

  test('discard drops the entry and clears the failed count', () async {
    final h = _harness();
    h.people.failWith = const NetworkException('Server asleep');
    final placeholder = h.queue.addPerson(firstName: 'Ada', lastName: 'L');
    await _settle();
    expect(h.container.read(pendingWritesProvider).failed, 1);

    h.queue.discard(placeholder.id);

    expect(h.queue.person(placeholder.id), isNull);
    expect(h.container.read(pendingCreatesProvider), isEmpty);
    expect(h.container.read(pendingWritesProvider).failed, 0);
  });

  test('a note about a pending person waits for the person and is posted '
      'with the real id', () async {
    final h = _harness();
    h.people.gate = Completer<void>();
    final person = h.queue.addPerson(firstName: 'Ada', lastName: 'L');
    final note = h.queue.addNote(
      person.id,
      content: 'First note',
      personName: 'Ada',
    );
    await _settle();

    expect(note.noteId, isNegative);
    expect(h.notes.created, isEmpty);
    // Both are counted while the note waits on the person.
    expect(h.container.read(pendingWritesProvider).inFlight, 2);

    h.people.gate!.complete();
    await _settle();
    await _settle();

    expect(h.notes.created.single.personId, 'real1');
    final entries = h.container.read(pendingCreatesProvider);
    final noteEntry = entries.whereType<PendingNote>().single;
    expect(noteEntry.isDone, isTrue);
    expect(noteEntry.note.noteId, 101);
    // The overlay still finds it under the real id.
    expect(
      pendingNotesFor(
        entries,
        'real1',
        shown: const [],
        resolve: h.queue.resolve,
      ),
      [noteEntry],
    );
  });

  test('when the person fails its dependents fail with the reason, and a '
      'successful retry of the person retries them', () async {
    final h = _harness();
    h.people.failWith = const NetworkException('Server asleep');
    final person = h.queue.addPerson(firstName: 'Ada', lastName: 'L');
    h.queue.addNote(person.id, content: 'Waiting', personName: 'Ada');
    h.queue.addRelationship(
      person.id,
      related: _byron,
      type: RelationshipType.parent,
      personName: 'Ada',
    );
    await _settle();
    await _settle();

    final entries = h.container.read(pendingCreatesProvider);
    expect(entries.every((e) => e.isFailed), isTrue);
    expect(
      entries.whereType<PendingNote>().single.error?.message,
      'Save Ada L first.',
    );
    expect(h.container.read(pendingWritesProvider).failed, 3);

    h.people.failWith = null;
    h.queue.retry(person.id);
    await _settle();
    await _settle();
    await _settle();

    expect(
      h.container.read(pendingCreatesProvider).every((e) => e.isDone),
      isTrue,
    );
    expect(h.notes.created.single.personId, 'real1');
    expect(h.relationships.created.single.relatedPersonId, _byron.id);
    expect(h.container.read(pendingWritesProvider).failed, 0);
  });

  test(
    'discarding a person takes its queued notes and relationships with it',
    () async {
      final h = _harness();
      h.people.gate = Completer<void>();
      final person = h.queue.addPerson(firstName: 'Ada', lastName: 'L');
      h.queue.addNote(person.id, content: 'Waiting', personName: 'Ada');
      await _settle();

      h.queue.discard(person.id);
      await _settle();

      expect(h.container.read(pendingCreatesProvider), isEmpty);
      // The person's request itself cannot be recalled - it is out at the
      // server - so it is still counted until it answers; the note never goes.
      expect(h.container.read(pendingWritesProvider).inFlight, 1);
      h.people.gate!.complete();
      await _settle();
      await _settle();
      expect(h.container.read(pendingWritesProvider).inFlight, 0);
      expect(h.notes.created, isEmpty);
    },
  );

  test('a relationship is posted at once for a real person and re-reads '
      'nothing locally', () async {
    final h = _harness();
    final placeholder = h.queue.addRelationship(
      'aB3xQ',
      related: _byron,
      type: RelationshipType.spouse,
      personName: 'Ada',
    );
    await _settle();

    expect(placeholder.relatedPersonName, 'Byron Lovelace');
    expect(h.relationships.created.single.personId, 'aB3xQ');
    expect(h.container.read(pendingCreatesProvider).single.isDone, isTrue);
  });

  test('the overlay hides a done entry once the list it is drawn over '
      'contains the record', () {
    final h = _harness();
    final person = h.queue.addPerson(firstName: 'Ada', lastName: 'L');
    final note = h.queue.addNote('aB3xQ', content: 'x', personName: 'Ada');
    final rel = h.queue.addRelationship(
      'aB3xQ',
      related: _byron,
      type: RelationshipType.spouse,
      personName: 'Ada',
    );
    // Every fake answered synchronously enough for these to be done.
    return Future<void>.delayed(Duration.zero).then((_) {
      final entries = h.container.read(pendingCreatesProvider);
      expect(entries.every((e) => e.isDone), isTrue);

      expect(pendingPeopleNotIn(entries, const []), hasLength(1));
      expect(
        pendingPeopleNotIn(entries, [person.copyWith(id: 'real1')]),
        isEmpty,
      );

      final landedNote = Note(noteId: 101, personId: 'aB3xQ', content: 'x');
      expect(
        pendingNotesFor(entries, 'aB3xQ', shown: const [], resolve: (id) => id),
        hasLength(1),
      );
      expect(
        pendingNotesFor(
          entries,
          'aB3xQ',
          shown: [landedNote],
          resolve: (id) => id,
        ),
        isEmpty,
      );

      expect(
        pendingRelationshipsFor(
          entries,
          'aB3xQ',
          shown: const [],
          resolve: (id) => id,
        ),
        hasLength(1),
      );
      expect(
        pendingRelationshipsFor(
          entries,
          'aB3xQ',
          shown: [rel.copyWith(relationshipId: 55)],
          resolve: (id) => id,
        ),
        isEmpty,
      );
      expect(note.noteId, isNegative);
    });
  });

  test('sign-out empties the queue', () async {
    final h = _harness();
    h.people.failWith = const NetworkException('Server asleep');
    h.queue.addPerson(firstName: 'Ada', lastName: 'L');
    await _settle();
    expect(h.container.read(pendingCreatesProvider), hasLength(1));

    h.container.read(sessionEndedProvider.notifier).bump();

    expect(h.container.read(pendingCreatesProvider), isEmpty);
    expect(h.container.read(pendingWritesProvider).failed, 0);
  });
}
