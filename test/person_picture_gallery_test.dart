import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/data/repositories/people_repository.dart';
import 'package:pham_dash_flutter/features/people/person_picture_gallery.dart';

const _person = Person(id: 'aB3xQ', firstName: 'Ha', lastName: 'Pham');

/// Pictures the tiles can render without reaching the network.
///
/// The paths are outside `/uploads/`, so `AppConfig.mediaUrl` returns null and
/// the tile draws its placeholder instead of a `CachedNetworkImage` — the same
/// reason the other widget tests here leave `profilePictureUrl` unset.
List<PersonPicture> _pictures({int primaryId = 2}) => [
      for (final id in [2, 1])
        PersonPicture(
          id: id,
          personId: _person.id,
          profilePictureUrl: '/profile-images/person_$id.png',
          isPrimary: id == primaryId,
        ),
    ];

/// Records what the gallery asked for.
///
/// Subclasses rather than implements: `PeopleRepository` holds a private
/// `ApiClient`, which another library cannot satisfy. Only the picture methods
/// are overridden, and nothing else is called, so the client is never touched.
class _RecordingPeople extends PeopleRepository {
  _RecordingPeople(super.api, this.stored);

  List<PersonPicture> stored;

  int? primarySetTo;
  int? deleted;

  @override
  Future<List<PersonPicture>> pictures(String personId) async => stored;

  @override
  Future<List<PersonPicture>> setPrimaryPicture(
    String personId,
    int pictureId,
  ) async {
    primarySetTo = pictureId;
    stored = _pictures(primaryId: pictureId);
    return stored;
  }

  @override
  Future<void> deletePicture(String personId, int pictureId) async {
    deleted = pictureId;
    stored = stored.where((picture) => picture.id != pictureId).toList();
  }
}

Future<_RecordingPeople> _pumpGallery(
  WidgetTester tester, {
  List<PersonPicture>? pictures,
}) async {
  final people = _RecordingPeople(
    ApiClient(AuthService()),
    pictures ?? _pictures(),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [peopleRepositoryProvider.overrideWithValue(people)],
      child: const MaterialApp(
        home: Scaffold(body: PersonPictureGallery(person: _person)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return people;
}

Finder _tile(int id) => find.byKey(ValueKey('picture-$id'));
Finder _deleteButton(int id) => find.byKey(ValueKey('delete-picture-$id'));

void main() {
  testWidgets('the displayed picture is the one badged', (tester) async {
    await _pumpGallery(tester);

    // Picture 2 is primary, so exactly one tile says so.
    expect(find.text('Shown'), findsOneWidget);
  });

  testWidgets('tapping a picture makes it the displayed one', (tester) async {
    final people = await _pumpGallery(tester);

    await tester.tap(_tile(1));
    await tester.pumpAndSettle();

    expect(people.primarySetTo, 1);
  });

  testWidgets('tapping the picture already shown asks the server for nothing',
      (tester) async {
    final people = await _pumpGallery(tester);

    await tester.tap(_tile(2));
    await tester.pumpAndSettle();

    expect(people.primarySetTo, isNull);
  });

  testWidgets('deleting asks first, and says what taking over means',
      (tester) async {
    final people = await _pumpGallery(tester);

    await tester.tap(_deleteButton(2));
    await tester.pumpAndSettle();

    // Deleting the shown picture silently changes the avatar everywhere, so the
    // confirmation has to name that consequence.
    expect(
      find.textContaining('most recent remaining picture will take over'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(people.deleted, isNull);
  });

  testWidgets('confirming the delete removes that picture', (tester) async {
    final people = await _pumpGallery(tester);

    await tester.tap(_deleteButton(1));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(people.deleted, 1);
  });

  testWidgets('adding is offered while there is room', (tester) async {
    await _pumpGallery(tester);

    expect(find.text('Add picture'), findsOneWidget);
  });

  testWidgets('adding is withdrawn at the cap rather than left to fail',
      (tester) async {
    // The picker is several taps; losing them to a 409 at the end is worse than
    // not offering it.
    await _pumpGallery(
      tester,
      pictures: [
        for (var id = 1; id <= maxPicturesPerPerson; id++)
          PersonPicture(id: id, personId: _person.id, isPrimary: id == 1),
      ],
    );

    expect(find.text('Add picture'), findsNothing);
    expect(
      find.textContaining('maximum of $maxPicturesPerPerson'),
      findsOneWidget,
    );
  });
}
