import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/sync/pending_writes.dart';
import '../../data/models/converters.dart';
import '../../data/models/people_models.dart';
import '../notes/recent_notes_tab.dart';
import 'people_providers.dart';

/// Creates in the people directory that the user has submitted and walked away
/// from: a person, a note, a relationship, each still on its way to the server
/// or already refused by it.
///
/// The todo detail patches its own list optimistically because it *owns* the
/// list. The people pages do not: `personNotesProvider` and friends are plain
/// `FutureProvider`s with nothing to patch, and the directory itself is
/// re-fetched after every write. So a pending record is not written into any
/// cache. It lives here, and each screen lays it over whatever list it is
/// showing - the person's own fetch, the bulk cache slice, the directory - until
/// the authoritative list contains it, at which point the entry is dropped and
/// the row it drew is replaced by the real one without a flicker.
///
/// **A person has no id until the server answers.** `POST /api/people` always
/// assigns its own, so a person waiting here is known by a `pending-<n>` id.
/// A hyphen cannot appear in a server id, so the two never collide, and
/// `/people/pending-1` is a real route: the detail page renders the placeholder
/// and lets notes and relationships be queued *against* it. Those wait on the
/// person's create and are posted with the real id when it lands; if it fails,
/// they fail too, with a message that says why, and a successful retry of the
/// person retries them.
///
/// **In memory only.** The 60 s request timeout outlasts a database wake, so
/// the request that is in flight when the user leaves the screen is the one
/// that lands. Nothing is written to disk and nothing is replayed on launch:
/// a create whose response was lost may well have been applied, and
/// re-sending it would make a second person. The cost is that killing the app
/// mid-save loses the entry, which the user sees at once - the row is gone.
///
/// Failures stay on screen as "couldn't save" with Retry and Discard, because
/// the alternative - rolling back a note the user typed on a page they have
/// since left - is losing their work silently. The count of failed entries is
/// reported to `pendingWritesProvider` so the app-bar glyph turns red wherever
/// they happen to be.
///
/// Not overlaid: the inverse row a relationship create puts on the *other*
/// person's page. What the server writes there depends on rules this client
/// does not reproduce (sibling groups, a spouse's copy of a child link), so
/// that page catches up on the invalidation that follows success.
final pendingCreatesProvider =
    NotifierProvider<PendingCreates, List<PendingCreate>>(PendingCreates.new);

enum PendingStatus { sending, failed, done }

/// One queued create. Immutable; the notifier replaces entries by [key].
sealed class PendingCreate {
  const PendingCreate({required this.status, this.error});

  /// Unique within the queue; the person's temp id, or `note:-3`.
  String get key;

  final PendingStatus status;

  /// Set while [status] is [PendingStatus.failed].
  final ApiException? error;

  /// What the failed-changes sheet calls this entry.
  String get label;

  bool get isSending => status == PendingStatus.sending;
  bool get isFailed => status == PendingStatus.failed;
  bool get isDone => status == PendingStatus.done;

  PendingCreate _copy({PendingStatus? status, ApiException? error});
}

class PendingPerson extends PendingCreate {
  const PendingPerson({
    required this.placeholder,
    required this.tagIds,
    this.picturePath,
    this.pictureName,
    this.realId,
    super.status = PendingStatus.sending,
    super.error,
  });

  /// The person as typed, under a `pending-<n>` id, with the ticked tags from
  /// the vocabulary so the chips show before the server has attached them.
  final Person placeholder;
  final Set<int> tagIds;

  /// The chosen but not yet uploaded picture, for the avatar meanwhile.
  final String? picturePath;
  final String? pictureName;

  /// The server's id, known once `POST /people` has answered - which may be
  /// before the tags and picture have finished. A retry after a failure in
  /// those later steps reuses it rather than creating the person twice.
  final String? realId;

  String get tempId => placeholder.id;

  @override
  String get key => tempId;

  @override
  String get label => placeholder.fullName;

  @override
  PendingPerson _copy({
    PendingStatus? status,
    ApiException? error,
    String? realId,
  }) => PendingPerson(
    placeholder: placeholder,
    tagIds: tagIds,
    picturePath: picturePath,
    pictureName: pictureName,
    realId: realId ?? this.realId,
    status: status ?? this.status,
    error: (status ?? this.status) == PendingStatus.failed
        ? (error ?? this.error)
        : null,
  );
}

class PendingNote extends PendingCreate {
  const PendingNote({
    required this.personRef,
    required this.placeholder,
    required this.personName,
    this.result,
    super.status = PendingStatus.sending,
    super.error,
  });

  /// The subject's id as it was when the note was written - a real id, or a
  /// pending person's temp id. [PendingCreates.resolve] maps the latter.
  final String personRef;

  /// Negative `noteId`, like the todo detail's placeholder items.
  final Note placeholder;

  /// For the label; the subject may not be in the directory yet.
  final String personName;

  /// The server's note, once it has answered. Shown in place of
  /// [placeholder] so the date is the server's, not the phone's.
  final Note? result;

  Note get note => result ?? placeholder;

  @override
  String get key => 'note:${placeholder.noteId}';

  @override
  String get label => 'Note about $personName';

  @override
  PendingNote _copy({
    PendingStatus? status,
    ApiException? error,
    Note? result,
  }) => PendingNote(
    personRef: personRef,
    placeholder: placeholder,
    personName: personName,
    result: result ?? this.result,
    status: status ?? this.status,
    error: (status ?? this.status) == PendingStatus.failed
        ? (error ?? this.error)
        : null,
  );
}

class PendingRelationship extends PendingCreate {
  const PendingRelationship({
    required this.personRef,
    required this.related,
    required this.placeholder,
    required this.personName,
    super.status = PendingStatus.sending,
    super.error,
  });

  /// See [PendingNote.personRef].
  final String personRef;

  /// The other person - always someone already in the directory, since the
  /// picker never offers a pending one.
  final Person related;

  /// Negative `relationshipId`, with the related person's display fields
  /// filled from [related] the way the server would denormalise them.
  final Relationship placeholder;

  final String personName;

  RelationshipType get type => placeholder.type;

  @override
  String get key => 'relationship:${placeholder.relationshipId}';

  @override
  String get label =>
      '${related.fullName} as $personName’s ${type.label.toLowerCase()}';

  @override
  PendingRelationship _copy({PendingStatus? status, ApiException? error}) =>
      PendingRelationship(
        personRef: personRef,
        related: related,
        placeholder: placeholder,
        personName: personName,
        status: status ?? this.status,
        error: (status ?? this.status) == PendingStatus.failed
            ? (error ?? this.error)
            : null,
      );
}

/// Whether [id] names a person this queue invented rather than the server.
bool isPendingPersonId(String id) => id.startsWith(PendingCreates.idPrefix);

class PendingCreates extends Notifier<List<PendingCreate>> {
  static const String idPrefix = 'pending-';

  /// Counter for temp ids. Static like the todo detail's, so ids stay unique
  /// across a sign-out that rebuilds the notifier.
  static int _next = 1;

  /// One per pending person, completed with the real id once `POST /people`
  /// answers, or with an error when it fails - which is what wakes a note
  /// waiting on it. Replaced on retry so the next wait is on the next attempt.
  final Map<String, Completer<String>> _resolvers = {};

  /// A person's resolver. Its error is what a waiting note reacts to, but
  /// there may be no note waiting when the person fails - so the future is
  /// marked as handled, or the failure would surface as an uncaught error.
  static Completer<String> _newResolver() {
    final completer = Completer<String>();
    completer.future.ignore();
    return completer;
  }

  @override
  List<PendingCreate> build() {
    // The queue belongs to whoever was signed in. `AuthController` clears the
    // disk cache itself but lives in core, where this provider is not visible.
    ref.listen(sessionEndedProvider, (_, _) => _clear());
    return const [];
  }

  /// Drops `done` entries whose record the bulk lists now hold. Hygiene only:
  /// the overlay helpers already hide a done entry once the list it is drawn
  /// over contains it. Reads the lists only when something already has them
  /// alive - this queue must not be what starts a directory fetch.
  void _pruneLanded() {
    final people = _valueIfAlive(allPeopleProvider);
    final notes = _valueIfAlive(allNotesProvider);
    final relationships = _valueIfAlive(allRelationshipsProvider);
    final personIds = people?.map((p) => p.id).toSet();
    final noteIds = notes?.map((n) => n.noteId).toSet();
    _prune(
      (e) =>
          e.isDone &&
          switch (e) {
            PendingPerson() => personIds?.contains(e.realId) ?? false,
            PendingNote() => noteIds?.contains(e.result?.noteId) ?? false,
            PendingRelationship() =>
              relationships?.any(
                    (r) => _sameRelationship(r, e, resolve(e.personRef)),
                  ) ??
                  false,
          },
    );
  }

  List<T>? _valueIfAlive<T>(AsyncNotifierProvider<dynamic, List<T>> provider) =>
      ref.exists(provider) ? ref.read(provider).value : null;

  // --- queries ---------------------------------------------------------------

  /// The real id for a pending person that has landed, else [id] unchanged.
  String resolve(String id) {
    if (!isPendingPersonId(id)) return id;
    return _personEntry(id)?.realId ?? id;
  }

  PendingPerson? person(String tempId) => _personEntry(tempId);

  PendingPerson? _personEntry(String tempId) => state
      .whereType<PendingPerson>()
      .where((p) => p.tempId == tempId)
      .firstOrNull;

  // --- enqueue ---------------------------------------------------------------

  /// Queues a person and returns the placeholder, whose id is the temp id the
  /// caller navigates to. Tags and the picture are applied after the create,
  /// in the same order the edit sheet used to run inline.
  Person addPerson({
    required String firstName,
    required String lastName,
    String? vietnameseName,
    String? homeAddress,
    DateTime? birthDate,
    Set<int> tagIds = const {},
    String? picturePath,
    String? pictureName,
  }) {
    final tempId = '$idPrefix${_next++}';
    final vocabulary =
        ref.read(personTagsProvider).value ?? const <PersonTag>[];
    final placeholder = Person(
      id: tempId,
      firstName: firstName,
      lastName: lastName,
      vietnameseName: vietnameseName,
      homeAddress: homeAddress,
      birthDate: birthDate,
      tags: [
        for (final tag in vocabulary)
          if (tagIds.contains(tag.id)) tag,
      ],
    );
    final entry = PendingPerson(
      placeholder: placeholder,
      tagIds: tagIds,
      picturePath: picturePath,
      pictureName: pictureName,
    );
    _resolvers[tempId] = _newResolver();
    _append(entry);
    _run(entry);
    return placeholder;
  }

  /// Queues a note about [personId] - real or pending. Returns the placeholder.
  Note addNote(
    String personId, {
    required String content,
    String? category,
    required String personName,
  }) {
    final placeholder = Note(
      noteId: -(_next++),
      personId: personId,
      content: content,
      category: category,
      createdAt: DateTime.now().toUtc(),
    );
    final entry = PendingNote(
      personRef: personId,
      placeholder: placeholder,
      personName: personName,
    );
    _append(entry);
    _run(entry);
    return placeholder;
  }

  /// Queues a relationship from [personId] - real or pending - to [related].
  Relationship addRelationship(
    String personId, {
    required Person related,
    required RelationshipType type,
    required String personName,
  }) {
    final placeholder = Relationship(
      relationshipId: -(_next++),
      personId: personId,
      relatedPersonId: related.id,
      type: type,
      createdAt: DateTime.now().toUtc(),
      relatedPersonFirstName: related.firstName,
      relatedPersonLastName: related.lastName,
      relatedPersonBirthDate: related.birthDate,
      relatedPersonProfilePictureUrl: related.profilePictureUrl,
    );
    final entry = PendingRelationship(
      personRef: personId,
      related: related,
      placeholder: placeholder,
      personName: personName,
    );
    _append(entry);
    _run(entry);
    return placeholder;
  }

  // --- retry / discard -------------------------------------------------------

  void retry(String key) {
    final entry = _entry(key);
    if (entry == null || !entry.isFailed) return;
    if (entry is PendingPerson) _resolvers[entry.tempId] = _newResolver();
    final sending = entry._copy(status: PendingStatus.sending);
    _replace(sending);
    _run(sending);
  }

  void retryAllFailed() {
    for (final entry in state.where((e) => e.isFailed).toList()) {
      retry(entry.key);
    }
  }

  /// Drops the entry. A person takes every note and relationship queued
  /// against it; they had nowhere else to go.
  void discard(String key) {
    final entry = _entry(key);
    if (entry == null) return;
    final dropped = <String>{key};
    if (entry is PendingPerson) {
      for (final e in state) {
        if (_personRefOf(e) == entry.tempId) dropped.add(e.key);
      }
      _resolvers
          .remove(entry.tempId)
          ?._failIfPending(
            const NetworkException('That person was discarded.'),
          );
    }
    state = [
      for (final e in state)
        if (!dropped.contains(e.key)) e,
    ];
    _syncFailedCount();
  }

  // --- the writes ------------------------------------------------------------

  Future<void> _run(PendingCreate entry) async {
    try {
      await ref
          .read(pendingWritesProvider.notifier)
          .track(
            () => switch (entry) {
              PendingPerson() => _runPerson(entry),
              PendingNote() => _runNote(entry),
              PendingRelationship() => _runRelationship(entry),
            },
          );
    } on ApiException catch (error) {
      _fail(entry.key, error);
    }
  }

  Future<void> _runPerson(PendingPerson entry) async {
    final people = ref.read(peopleRepositoryProvider);
    final draft = entry.placeholder;

    var realId = entry.realId;
    if (realId == null) {
      final created = await people.create(
        firstName: draft.firstName,
        lastName: draft.lastName,
        vietnameseName: draft.vietnameseName,
        homeAddress: draft.homeAddress,
        birthDate: draft.birthDate,
      );
      if (created == null) {
        throw const ApiException(null, 'The server did not return the person.');
      }
      final id = created.id;
      realId = id;
      // Known from here on, even if a tag or the picture fails below: the
      // retry must not create them again, and a note waiting on this person
      // needs nothing more than the id.
      _update(entry.key, (e) => (e as PendingPerson)._copy(realId: id));
      _resolvers[entry.tempId]?._completeIfPending(id);
    }

    final tags = ref.read(personTagsRepositoryProvider);
    for (final tagId in entry.tagIds) {
      // Idempotent server-side, so a retry re-attaching the first few is fine.
      await tags.attach(realId, tagId);
    }
    if (entry.picturePath case final path?) {
      await people.uploadProfilePicture(
        realId,
        filePath: path,
        fileName: entry.pictureName ?? path.split(RegExp(r'[\\/]')).last,
      );
    }

    _update(entry.key, (e) => e._copy(status: PendingStatus.done));
    invalidatePersonIn(ref, realId);
    // Anything that gave up while this person was failing can go now.
    for (final e in state) {
      if (e.isFailed && _personRefOf(e) == entry.tempId) retry(e.key);
    }
  }

  Future<void> _runNote(PendingNote entry) async {
    final personId = await _awaitPerson(entry.personRef);
    final created = await ref
        .read(notesRepositoryProvider)
        .create(
          personId,
          content: entry.placeholder.content,
          category: entry.placeholder.category,
        );
    _update(
      entry.key,
      (e) =>
          (e as PendingNote)._copy(status: PendingStatus.done, result: created),
    );
    ref.invalidate(personNotesProvider(personId));
    ref.invalidate(allNotesProvider);
    ref.invalidate(recentNotesProvider);
  }

  Future<void> _runRelationship(PendingRelationship entry) async {
    final personId = await _awaitPerson(entry.personRef);
    await ref
        .read(relationshipsRepositoryProvider)
        .create(personId, relatedPersonId: entry.related.id, type: entry.type);
    _update(entry.key, (e) => e._copy(status: PendingStatus.done));
    invalidatePersonIn(ref, personId);
    invalidatePersonIn(ref, entry.related.id);
  }

  /// The real id behind [personRef], waiting for the create if it is still
  /// out. A failed or discarded person throws a [NetworkException] whose
  /// message the dependent row can show as-is.
  Future<String> _awaitPerson(String personRef) async {
    if (!isPendingPersonId(personRef)) return personRef;
    final person = _personEntry(personRef);
    if (person == null) {
      throw const NetworkException('That person was discarded.');
    }
    if (person.realId case final id?) return id;
    if (person.isFailed) {
      throw NetworkException('Save ${person.placeholder.fullName} first.');
    }
    return _resolvers[personRef]!.future;
  }

  void _fail(String key, ApiException error) {
    final entry = _entry(key);
    if (entry == null) return;
    _replace(entry._copy(status: PendingStatus.failed, error: error));
    if (entry is PendingPerson && entry.realId == null) {
      // Wake the notes waiting on this person so they fail with a reason,
      // and give the next attempt a fresh wait of its own.
      _resolvers[entry.tempId]?._failIfPending(
        NetworkException('Save ${entry.placeholder.fullName} first.'),
      );
      _resolvers[entry.tempId] = _newResolver();
    }
  }

  // --- state plumbing --------------------------------------------------------

  PendingCreate? _entry(String key) =>
      state.where((e) => e.key == key).firstOrNull;

  void _append(PendingCreate entry) {
    _pruneLanded();
    state = [...state, entry];
    _syncFailedCount();
  }

  void _replace(PendingCreate entry) {
    state = [for (final e in state) e.key == entry.key ? entry : e];
    _syncFailedCount();
  }

  void _update(String key, PendingCreate Function(PendingCreate) change) {
    final entry = _entry(key);
    // Discarded while the request was out: nothing to update.
    if (entry != null) _replace(change(entry));
  }

  void _prune(bool Function(PendingCreate) test) {
    if (!state.any(test)) return;
    state = [
      for (final e in state)
        if (!test(e)) e,
    ];
  }

  void _clear() {
    for (final resolver in _resolvers.values) {
      resolver._failIfPending(const NetworkException('Signed out.'));
    }
    _resolvers.clear();
    state = const [];
    _syncFailedCount();
  }

  void _syncFailedCount() => ref
      .read(pendingWritesProvider.notifier)
      .setFailed(state.where((e) => e.isFailed).length);

  static String? _personRefOf(PendingCreate entry) => switch (entry) {
    PendingNote() => entry.personRef,
    PendingRelationship() => entry.personRef,
    PendingPerson() => null,
  };

  static bool _sameRelationship(
    Relationship row,
    PendingRelationship entry,
    String personId,
  ) =>
      row.personId == personId &&
      row.relatedPersonId == entry.related.id &&
      row.type == entry.type;
}

extension on Completer<String> {
  void _completeIfPending(String value) {
    if (!isCompleted) complete(value);
  }

  void _failIfPending(Object error) {
    if (!isCompleted) completeError(error);
  }
}

// --- overlays ----------------------------------------------------------------
//
// Pure functions over the queue's state, so a screen can lay pending records
// over whichever list it is showing and a test can check the rule without a
// widget. Each drops a `done` entry once [shown] already contains the record,
// which is what keeps a row from blinking when the fetch catches up.

/// Pending people not yet in [directory], for the People list.
List<PendingPerson> pendingPeopleNotIn(
  List<PendingCreate> queue,
  List<Person> directory,
) {
  final ids = {for (final p in directory) p.id};
  return [
    for (final e in queue.whereType<PendingPerson>())
      if (!(e.isDone && ids.contains(e.realId))) e,
  ];
}

/// Pending notes about [personId] - matched on the id as it was queued and on
/// what it resolves to, so a note queued against `pending-1` stays on the page
/// after it becomes `Xy3Za` - not already among [shown].
List<PendingNote> pendingNotesFor(
  List<PendingCreate> queue,
  String personId, {
  required List<Note> shown,
  required String Function(String) resolve,
}) {
  final ids = {for (final n in shown) n.noteId};
  return [
    for (final e in queue.whereType<PendingNote>())
      if ((e.personRef == personId || resolve(e.personRef) == personId) &&
          !(e.isDone && ids.contains(e.result?.noteId)))
        e,
  ];
}

/// Pending relationships from [personId], not already among [shown]; see
/// [pendingNotesFor] for the id matching.
List<PendingRelationship> pendingRelationshipsFor(
  List<PendingCreate> queue,
  String personId, {
  required List<Relationship> shown,
  required String Function(String) resolve,
}) => [
  for (final e in queue.whereType<PendingRelationship>())
    if ((e.personRef == personId || resolve(e.personRef) == personId) &&
        !(e.isDone &&
            shown.any(
              (r) => r.relatedPersonId == e.related.id && r.type == e.type,
            )))
      e,
];
