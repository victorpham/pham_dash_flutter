import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../core/cache/cached_list.dart';
import '../../core/cache/stale_refresh.dart';
import '../../core/providers.dart';
import '../../data/models/people_models.dart';

/// The people directory.
///
/// Not user-scoped — `Person` has no `UserId` column, so this is the same list
/// for every authenticated user. Kept alive rather than `autoDispose` because
/// three separate pickers and the people screen all read it, and re-fetching
/// the whole directory each time one opens is wasteful.
final allPeopleProvider =
    AsyncNotifierProvider<AllPeopleNotifier, List<Person>>(
  AllPeopleNotifier.new,
);

class AllPeopleNotifier extends AsyncNotifier<List<Person>>
    with CachedList<Person> {
  @override
  Future<List<Person>> build() {
    // Profile-picture URLs in the cached copy carry a signature that lasts
    // two days; older than that, `PersonAvatar` shows initials until the
    // fresh list lands. Acceptable for a few seconds of stale directory.
    persistList(
      'people',
      fromJson: Person.fromJson,
      toJson: (person) => person.toJson(),
    );
    return ref.watch(peopleRepositoryProvider).all();
  }
}

/// Every note, for every person.
///
/// Exists so a person page can render its Notes section from the cache before
/// its own fetch answers - which, after an hour idle, is tens of seconds of
/// database resume. The page slices this with [notesFor]; [personNotesProvider]
/// stays the authoritative answer and replaces the slice when it lands.
///
/// Keep-alive like [allPeopleProvider], and refreshed by
/// [directoryRefreshProvider] rather than on every read. The whole table is a
/// few dozen rows.
final allNotesProvider = AsyncNotifierProvider<AllNotesNotifier, List<Note>>(
  AllNotesNotifier.new,
);

class AllNotesNotifier extends AsyncNotifier<List<Note>> with CachedList<Note> {
  @override
  Future<List<Note>> build() {
    persistList('notes', fromJson: Note.fromJson, toJson: (n) => n.toJson());
    return ref.watch(notesRepositoryProvider).all();
  }
}

/// Every relationship row, for every person - see [allNotesProvider] for why.
final allRelationshipsProvider =
    AsyncNotifierProvider<AllRelationshipsNotifier, List<Relationship>>(
  AllRelationshipsNotifier.new,
);

class AllRelationshipsNotifier extends AsyncNotifier<List<Relationship>>
    with CachedList<Relationship> {
  @override
  Future<List<Relationship>> build() {
    persistList(
      'relationships',
      fromJson: Relationship.fromJson,
      toJson: (r) => r.toJson(),
    );
    return ref.watch(relationshipsRepositoryProvider).all();
  }
}

/// [personId]'s slice of the bulk notes cache, or null when nothing is cached
/// yet. The distinction between "no notes" and "not known" is what lets the
/// section show an empty state for the first and a spinner for the second.
///
/// No sort: `/api/notes` is newest-first like `/api/people/{id}/notes`, and a
/// filter keeps that order. Reads `.value`, never the error, so a bulk fetch
/// that failed - a 404 from an API that predates the endpoint, say - degrades
/// to the uncached behaviour rather than surfacing anything.
List<Note>? notesFor(AsyncValue<List<Note>> all, String personId) =>
    all.value?.where((note) => note.personId == personId).toList();

/// [personId]'s slice of the bulk relationships cache; see [notesFor].
/// `RelationshipGroups.from` does its own ordering.
List<Relationship>? relationshipsFor(
  AsyncValue<List<Relationship>> all,
  String personId,
) =>
    all.value?.where((r) => r.personId == personId).toList();

/// One person, for the detail screen.
///
/// 404s with a bare string body rather than the usual `{message,statusCode}`;
/// `ApiClient` already degrades to using it as the message.
final personProvider = FutureProvider.autoDispose.family<Person?, String>(
  (ref, id) => ref.watch(peopleRepositoryProvider).byId(id),
);

/// A person's notes, newest first.
final personNotesProvider = FutureProvider.autoDispose.family<List<Note>, String>(
  (ref, personId) => ref.watch(notesRepositoryProvider).forPerson(personId),
);

final personRelationshipsProvider =
    FutureProvider.autoDispose.family<List<Relationship>, String>(
  (ref, personId) =>
      ref.watch(relationshipsRepositoryProvider).forPerson(personId),
);

/// A person's gallery, the displayed picture first.
///
/// Cached per person, unlike notes and relationships, because there is no
/// bulk pictures endpoint to slice: a gallery opened before is instant, a
/// first open still waits. Same caveat as [AllPeopleNotifier] - the cached
/// URLs are signed for two days, and an older copy shows broken tiles until
/// the fresh list lands.
final personPicturesProvider = AsyncNotifierProvider.autoDispose
    .family<PersonPicturesNotifier, List<PersonPicture>, String>(
  PersonPicturesNotifier.new,
);

class PersonPicturesNotifier extends AsyncNotifier<List<PersonPicture>>
    with CachedList<PersonPicture> {
  PersonPicturesNotifier(this.personId);

  final String personId;

  @override
  Future<List<PersonPicture>> build() {
    persistList(
      'pictures:$personId',
      fromJson: PersonPicture.fromJson,
      toJson: (picture) => picture.toJson(),
    );
    return ref.watch(peopleRepositoryProvider).pictures(personId);
  }
}

/// The shared tag vocabulary.
///
/// Not user-scoped, like the people it describes. Kept alive rather than
/// `autoDispose` for the same reason as [allPeopleProvider]: the filter bar,
/// the chips on a person's page, the edit sheet and the manage sheet all read
/// it.
///
/// There is deliberately no per-person tags provider — a person's tags ride on
/// [Person.tags], so the detail page needs no second request and no second
/// `AsyncValue` to unwrap.
final personTagsProvider =
    AsyncNotifierProvider<PersonTagsNotifier, List<PersonTag>>(
  PersonTagsNotifier.new,
);

class PersonTagsNotifier extends AsyncNotifier<List<PersonTag>>
    with CachedList<PersonTag> {
  @override
  Future<List<PersonTag>> build() {
    persistList(
      'person_tags',
      fromJson: PersonTag.fromJson,
      toJson: (tag) => tag.toJson(),
    );
    return ref.watch(personTagsRepositoryProvider).all();
  }
}

/// The launch / resume / people-list-open check for new directory data.
///
/// The four keep-alive lists above would otherwise hold their first answer
/// for the life of the app. Keys must match each notifier's `persistList`
/// key, because the freshness stamp is what the throttle reads.
final directoryRefreshProvider = Provider<StaleRefresh>(
  (ref) => StaleRefresh(
    ref,
    entries: {
      'people': allPeopleProvider,
      'notes': allNotesProvider,
      'relationships': allRelationshipsProvider,
      'person_tags': personTagsProvider,
    },
  ),
);

/// Invalidates everything a write to [personId] can affect.
///
/// A relationship write is the reason this exists: the server fans one create
/// out into several rows — the inverse, every sibling in the group, a spouse's
/// copy of a child link — so patching local state is not an option, and the
/// *other* person's page is stale too. Blunt but correct.
void invalidatePerson(WidgetRef ref, String personId) =>
    _invalidatePerson(ref.invalidate, personId);

/// [invalidatePerson] for a notifier. `WidgetRef` and `Ref` share no type
/// that carries `invalidate`, so both hand their tear-off to the same body.
void invalidatePersonIn(Ref ref, String personId) =>
    _invalidatePerson(ref.invalidate, personId);

void _invalidatePerson(
  void Function(ProviderOrFamily provider) invalidate,
  String personId,
) {
  invalidate(personProvider(personId));
  invalidate(personNotesProvider(personId));
  invalidate(personRelationshipsProvider(personId));
  invalidate(personPicturesProvider(personId));
  invalidate(allPeopleProvider);
  // The bulk copies seed every other person's page, including the one on the
  // far end of that relationship.
  invalidate(allNotesProvider);
  invalidate(allRelationshipsProvider);
  // Attaching or detaching moves that tag's server-side `personCount`, which
  // the manage sheet shows.
  invalidate(personTagsProvider);
}

/// Invalidates what a change to the tag *vocabulary* affects.
///
/// Wider than it looks: tags are embedded on every [Person], so a rename or a
/// recolour leaves the old value on every person already in the cache. The
/// directory has to be re-read, not just the vocabulary — this is the price of
/// embedding, and it must be paid at every vocabulary write.
void invalidateTags(WidgetRef ref) {
  ref.invalidate(personTagsProvider);
  ref.invalidate(allPeopleProvider);
}
