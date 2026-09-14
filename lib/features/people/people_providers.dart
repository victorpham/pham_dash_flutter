import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/people_models.dart';

/// The people directory.
///
/// Not user-scoped — `Person` has no `UserId` column, so this is the same list
/// for every authenticated user. Kept alive rather than `autoDispose` because
/// three separate pickers and the people screen all read it, and re-fetching
/// the whole directory each time one opens is wasteful.
final allPeopleProvider = FutureProvider<List<Person>>(
  (ref) => ref.watch(peopleRepositoryProvider).all(),
);

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
final personPicturesProvider =
    FutureProvider.autoDispose.family<List<PersonPicture>, String>(
  (ref, personId) => ref.watch(peopleRepositoryProvider).pictures(personId),
);

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
final personTagsProvider = FutureProvider<List<PersonTag>>(
  (ref) => ref.watch(personTagsRepositoryProvider).all(),
);

/// Invalidates everything a write to [personId] can affect.
///
/// A relationship write is the reason this exists: the server fans one create
/// out into several rows — the inverse, every sibling in the group, a spouse's
/// copy of a child link — so patching local state is not an option, and the
/// *other* person's page is stale too. Blunt but correct.
void invalidatePerson(WidgetRef ref, String personId) {
  ref.invalidate(personProvider(personId));
  ref.invalidate(personNotesProvider(personId));
  ref.invalidate(personRelationshipsProvider(personId));
  ref.invalidate(personPicturesProvider(personId));
  ref.invalidate(allPeopleProvider);
  // Attaching or detaching moves that tag's server-side `personCount`, which
  // the manage sheet shows.
  ref.invalidate(personTagsProvider);
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
