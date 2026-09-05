import '../../core/api/api_client.dart';
import '../models/converters.dart';
import '../models/people_models.dart';
import '../models/preference_models.dart';
import 'decode.dart';

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
    DateTime? birthDate,
  }) async =>
      decodeOrNull(
        await _api.post<dynamic>(
          '/people',
          body: _personBody(firstName, lastName, vietnameseName, birthDate),
        ),
        Person.fromJson,
      );

  /// Only `firstName`, `lastName`, `vietnameseName` and `birthDate` are
  /// applied. `profilePictureUrl` is deliberately **not** updatable here - use
  /// [uploadProfilePicture], which also deletes the previous file.
  Future<Person?> update(
    String id, {
    required String firstName,
    required String lastName,
    String? vietnameseName,
    DateTime? birthDate,
  }) async =>
      decodeOrNull(
        await _api.put<dynamic>(
          '/people/$id',
          body: _personBody(firstName, lastName, vietnameseName, birthDate),
        ),
        Person.fromJson,
      );

  Future<void> delete(String id) => _api.delete('/people/$id');

  /// `.jpg .jpeg .png .gif .webp`, max 5 MB. Returns the new root-relative
  /// path; resolve it with `AppConfig.mediaUrl`.
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

  static Map<String, dynamic> _personBody(
    String firstName,
    String lastName,
    String? vietnameseName,
    DateTime? birthDate,
  ) =>
      {
        'firstName': firstName,
        'lastName': lastName,
        'vietnameseName': ?vietnameseName,
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
