import '../../core/api/api_client.dart';
import '../models/converters.dart';
import '../models/people_models.dart';
import '../models/preference_models.dart';
import 'decode.dart';

/// The server's per-person picture ceiling, mirrored here so the UI can hide
/// "add" at the limit rather than waiting for the 409.
const int maxPicturesPerPerson = 10;

/// People, their notes and their relationships.
///
/// None of these are user-scoped - `Person` has no `UserId` column, so every
/// authenticated user sees the same directory. That is intentional for a
/// single-family dashboard.
class PeopleRepository {
  const PeopleRepository(this._api);

  final ApiClient _api;

  /// Sorted by last name, then first name.
  Future<List<Person>> all() async =>
      decodeList(await _api.get<dynamic>('/people'), Person.fromJson);

  /// 404s with a **bare string body**, not JSON - `ApiClient` already degrades
  /// to using it as the message.
  Future<Person?> byId(String id) async =>
      decodeOrNull(await _api.get<dynamic>('/people/$id'), Person.fromJson);

  Future<List<UpcomingBirthday>> upcomingBirthdays({int count = 10}) async =>
      decodeList(
        await _api.get<dynamic>(
          '/people/upcoming-birthdays',
          query: {'count': count},
        ),
        UpcomingBirthday.fromJson,
      );

  Future<Person?> create({
    required String firstName,
    required String lastName,
    String? vietnameseName,
    String? homeAddress,
    DateTime? birthDate,
  }) async =>
      decodeOrNull(
        await _api.post<dynamic>(
          '/people',
          body: _personBody(
            firstName: firstName,
            lastName: lastName,
            vietnameseName: vietnameseName,
            homeAddress: homeAddress,
            birthDate: birthDate,
          ),
        ),
        Person.fromJson,
      );

  /// Only `firstName`, `lastName`, `vietnameseName`, `homeAddress` and
  /// `birthDate` are applied. `profilePictureUrl` is deliberately **not**
  /// updatable here - use [uploadProfilePicture], which also deletes the
  /// previous file.
  Future<Person?> update(
    String id, {
    required String firstName,
    required String lastName,
    String? vietnameseName,
    String? homeAddress,
    DateTime? birthDate,
  }) async =>
      decodeOrNull(
        await _api.put<dynamic>(
          '/people/$id',
          body: _personBody(
            firstName: firstName,
            lastName: lastName,
            vietnameseName: vietnameseName,
            homeAddress: homeAddress,
            birthDate: birthDate,
          ),
        ),
        Person.fromJson,
      );

  Future<void> delete(String id) => _api.delete('/people/$id');

  /// `.jpg .jpeg .png .gif .webp`, max 5 MB. Returns the new root-relative
  /// path; resolve it with `AppConfig.mediaUrl`.
  ///
  /// Adds to the person's gallery and makes the new picture the displayed one.
  /// Used by the create flow, which has no gallery to show yet; editing goes
  /// through [addPicture] instead so it gets the full picture back.
  Future<String?> uploadProfilePicture(
    String id, {
    required String filePath,
    required String fileName,
  }) async {
    final data = await _api.upload<dynamic>(
      '/people/$id/profile-picture',
      filePath: filePath,
      fileName: fileName,
    );
    return data is Map ? data['profilePictureUrl'] as String? : null;
  }

  /// Every picture the person has, the displayed one first then newest first.
  Future<List<PersonPicture>> pictures(String personId) async => decodeList(
        await _api.get<dynamic>('/people/$personId/pictures'),
        PersonPicture.fromJson,
      );

  /// Adds a picture and makes it the displayed one.
  ///
  /// 409s once the person is at [maxPicturesPerPerson]; the message is worth
  /// showing as-is.
  Future<PersonPicture?> addPicture(
    String personId, {
    required String filePath,
    required String fileName,
  }) async =>
      decodeOrNull(
        await _api.upload<dynamic>(
          '/people/$personId/pictures',
          filePath: filePath,
          fileName: fileName,
        ),
        PersonPicture.fromJson,
      );

  /// Chooses which picture is displayed. Returns the refreshed gallery, so the
  /// caller does not need a second round trip to redraw it.
  Future<List<PersonPicture>> setPrimaryPicture(
    String personId,
    int pictureId,
  ) async =>
      decodeList(
        await _api.post<dynamic>('/people/$personId/pictures/$pictureId/primary'),
        PersonPicture.fromJson,
      );

  /// Permanent — the row and the file both go. If it was the displayed picture
  /// the server promotes the next most recent, so re-read after this.
  Future<void> deletePicture(String personId, int pictureId) =>
      _api.delete('/people/$personId/pictures/$pictureId');

  /// Named rather than positional: with two adjacent optional `String?`s, a
  /// transposed pair of arguments would compile and silently write the address
  /// into the Vietnamese name.
  ///
  /// Omitting a key is how a field gets **cleared**. `PUT /api/people/{id}`
  /// binds the entity, so a missing key deserializes to null server-side and
  /// the repository copies that null over the stored value. Do not "fix" the
  /// null-aware entries below into unconditional ones - that would send
  /// `null` explicitly, which happens to work, but it would also start sending
  /// every field on every write.
  static Map<String, dynamic> _personBody({
    required String firstName,
    required String lastName,
    String? vietnameseName,
    String? homeAddress,
    DateTime? birthDate,
  }) =>
      {
        'firstName': firstName,
        'lastName': lastName,
        'vietnameseName': ?vietnameseName,
        'homeAddress': ?homeAddress,
        if (birthDate != null)
          'birthDate':
              '${birthDate.year.toString().padLeft(4, '0')}-'
                  '${birthDate.month.toString().padLeft(2, '0')}-'
                  '${birthDate.day.toString().padLeft(2, '0')}T00:00:00',
      };
}

/// Notes attached to people.
class NotesRepository {
  const NotesRepository(this._api);

  final ApiClient _api;

  /// The only notes endpoint that embeds the author `person`, which is what
  /// lets the recent-notes feed render avatars without a request per row.
  Future<List<Note>> recent({int count = 10}) async => decodeList(
        await _api.get<dynamic>('/notes/recent', query: {'count': count}),
        Note.fromJson,
      );

  /// Newest first.
  Future<List<Note>> forPerson(String personId) async => decodeList(
        await _api.get<dynamic>('/people/$personId/notes'),
        Note.fromJson,
      );

  Future<Note?> create(
    String personId, {
    required String content,
    String? category,
  }) async =>
      decodeOrNull(
        await _api.post<dynamic>(
          '/people/$personId/notes',
          body: {'content': content, 'category': ?category},
        ),
        Note.fromJson,
      );

  Future<Note?> update(
    String personId,
    int noteId, {
    required String content,
    String? category,
  }) async =>
      decodeOrNull(
        await _api.put<dynamic>(
          '/people/$personId/notes/$noteId',
          body: {'content': content, 'category': ?category},
        ),
        Note.fromJson,
      );

  Future<void> delete(String personId, int noteId) =>
      _api.delete('/people/$personId/notes/$noteId');
}

/// Typed relationships between people.
class RelationshipsRepository {
  const RelationshipsRepository(this._api);

  final ApiClient _api;

  Future<List<Relationship>> forPerson(String personId) async => decodeList(
        await _api.get<dynamic>('/people/$personId/relationships'),
        Relationship.fromJson,
      );

  /// Creates one relationship - and the server may create several more.
  ///
  /// It always writes the inverse (Spouse<->Spouse, Parent<->Child, ...), links
  /// a new sibling to every existing sibling in the group, and gives a parent's
  /// spouse the same child link. **Re-fetch the list afterwards** instead of
  /// patching local state.
  ///
  /// Rejected with 400 for a self-relationship, an unknown person, a duplicate,
  /// or a conflicting type - Parent/Child/Spouse/Sibling are mutually exclusive
  /// between any two people. Friend conflicts with nothing.
  Future<void> create(
    String personId, {
    required String relatedPersonId,
    required RelationshipType type,
  }) =>
      _api.post<dynamic>(
        '/people/$personId/relationships',
        body: {'relatedPersonId': relatedPersonId, 'type': type.wireValue},
      );

  /// Removes the relationship and its inverse, but does not unwind cascades.
  Future<void> delete(String personId, int relationshipId) =>
      _api.delete('/people/$personId/relationships/$relationshipId');
}

/// The shared people tag vocabulary, and the routes that attach it.
///
/// Not user-scoped: there is one vocabulary for the whole family, so [update]
/// and [delete] change what everyone sees.
class PersonTagsRepository {
  const PersonTagsRepository(this._api);

  final ApiClient _api;

  /// Every tag, ordered by name, each with a real `personCount`.
  Future<List<PersonTag>> all() async => decodeList(
        await _api.get<dynamic>('/person-tags'),
        PersonTag.fromJson,
      );

  /// Conflicts (409) when a tag of this name already exists - the comparison is
  /// case-insensitive server-side, so "Pickleball" collides with "pickleball".
  Future<PersonTag?> create(String name, {String? color}) async =>
      decodeOrNull(
        await _api.post<dynamic>(
          '/person-tags',
          body: {'name': name, 'color': ?color},
        ),
        PersonTag.fromJson,
      );

  /// Renames or recolours for everyone. Conflicts (409) on a duplicate name.
  Future<PersonTag?> update(int tagId, {String? name, String? color}) async =>
      decodeOrNull(
        await _api.put<dynamic>(
          '/person-tags/$tagId',
          body: {'name': ?name, 'color': ?color},
        ),
        PersonTag.fromJson,
      );

  /// Deletes the tag and takes it off every person carrying it, for every user.
  /// The people themselves are untouched.
  Future<void> delete(int tagId) => _api.delete('/person-tags/$tagId');

  /// Rarely needed - the same tags ride on [Person.tags]. Here for callers that
  /// hold only an id.
  Future<List<PersonTag>> forPerson(String personId) async => decodeList(
        await _api.get<dynamic>('/people/$personId/tags'),
        PersonTag.fromJson,
      );

  /// **Idempotent**: attaching a tag the person already carries succeeds and
  /// changes nothing. That differs from the event-category endpoints, which
  /// conflict, and it is what lets a picker toggle optimistically without a
  /// correct tick being rolled back by a 409.
  Future<void> attach(String personId, int tagId) =>
      _api.post<dynamic>('/people/$personId/tags/$tagId');

  /// Idempotent, as [attach] is.
  Future<void> detach(String personId, int tagId) =>
      _api.delete('/people/$personId/tags/$tagId');

  /// Everyone carrying [tagId]. The directory is filtered client-side from
  /// `allPeopleProvider`, so this is for callers without that list loaded.
  Future<List<Person>> peopleWithTag(int tagId) async => decodeList(
        await _api.get<dynamic>('/person-tags/$tagId/people'),
        Person.fromJson,
      );
}

/// `GET`/`PUT /api/user-preferences`.
class UserPreferenceRepository {
  const UserPreferenceRepository(this._api);

  final ApiClient _api;

  /// Never 404s - an unsaved profile comes back as an all-null object.
  Future<UserPreference> get() async {
    final data = await _api.get<dynamic>('/user-preferences');
    return decodeOrNull(data, UserPreference.fromJson) ??
        const UserPreference();
  }

  /// **Full upsert-replace: every field omitted is written as null.**
  ///
  /// Read, merge, then write - never send a partial body. The MVP does not call
  /// this at all, because a careless write from the phone would wipe the theme
  /// the web app has saved.
  Future<UserPreference> replace(UserPreference merged) async {
    final data =
        await _api.put<dynamic>('/user-preferences', body: merged.toJson());
    return decodeOrNull(data, UserPreference.fromJson) ?? merged;
  }
}
