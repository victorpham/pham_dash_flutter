import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/data/repositories/people_repository.dart';
import 'package:pham_dash_flutter/features/notes/add_note_sheet.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';

const _people = [
  Person(id: 'a1', firstName: 'Ha', lastName: 'Pham'),
  Person(id: 'b2', firstName: 'Minh', lastName: 'Nguyen'),
];

/// Records what the sheet sent, so the test can assert the chosen person's id
/// actually reached the person-scoped endpoint.
///
/// Subclasses rather than implements: `NotesRepository` holds a private
/// `ApiClient`, which another library cannot satisfy. Only [create] is
/// overridden and nothing else is called, so the client is never touched.
class _RecordingNotes extends NotesRepository {
  _RecordingNotes(super.api);

  ({String personId, String content, String? category})? created;

  /// Holds the create open, the way a sleeping database does.
  Completer<void>? gate;

  @override
  Future<Note?> create(
    String personId, {
    required String content,
    String? category,
  }) async {
    await gate?.future;
    created = (personId: personId, content: content, category: category);
    return Note(noteId: 1, personId: personId, content: content);
  }
}

_RecordingNotes _fakeNotes() => _RecordingNotes(ApiClient(AuthService()));

Future<_RecordingNotes> _pumpSheet(WidgetTester tester, {Person? person}) async {
  final notes = _fakeNotes();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        allPeopleProvider.overrideWithBuild((ref, _) => _people),
        notesRepositoryProvider.overrideWithValue(notes),
      ],
      child: MaterialApp(home: Scaffold(body: AddNoteSheet(person: person))),
    ),
  );
  await tester.pumpAndSettle();
  return notes;
}

Finder _saveButton() => find.widgetWithText(FilledButton, 'Save note');

Future<void> _choose(WidgetTester tester, String name) async {
  await tester.tap(find.text('Who is this note about?'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('saving is blocked until a person is chosen', (tester) async {
    await _pumpSheet(tester);

    // Content alone is not enough: the create route is person-scoped, so a
    // note with no subject has nowhere to go.
    await tester.enterText(find.byType(TextField).first, 'Lost a tooth');
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(_saveButton()).onPressed, isNull);
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('saving is blocked until something has been written',
      (tester) async {
    await _pumpSheet(tester);
    await _choose(tester, 'Minh Nguyen');

    expect(find.text('Minh Nguyen'), findsOneWidget);
    expect(tester.widget<FilledButton>(_saveButton()).onPressed, isNull);
  });

  testWidgets('the chosen person is who the note is filed against',
      (tester) async {
    final notes = await _pumpSheet(tester);
    await _choose(tester, 'Minh Nguyen');

    await tester.enterText(find.byType(TextField).first, 'Lost a tooth');
    await tester.enterText(find.byType(TextField).last, 'Milestones');
    await tester.pumpAndSettle();

    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    expect(notes.created?.personId, 'b2');
    expect(notes.created?.content, 'Lost a tooth');
    expect(notes.created?.category, 'Milestones');
  });

  testWidgets('an omitted category is sent as null, not as an empty string',
      (tester) async {
    final notes = await _pumpSheet(tester);
    await _choose(tester, 'Ha Pham');

    await tester.enterText(find.byType(TextField).first, 'Started school');
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    expect(notes.created?.category, isNull);
  });

  testWidgets('a caller that already knows the person skips the picker',
      (tester) async {
    await _pumpSheet(tester, person: _people.first);

    expect(find.text('Ha Pham'), findsOneWidget);
    expect(find.text('Who is this note about?'), findsNothing);
  });

  testWidgets('the sheet closes before the server has answered', (tester) async {
    // A create held open, as the database wake holds every first request.
    final gate = Completer<void>();
    final notes = _fakeNotes()..gate = gate;

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          allPeopleProvider.overrideWithBuild((ref, _) => _people),
          notesRepositoryProvider.overrideWithValue(notes),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAddNoteSheet(context, person: _people.first),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Lost a tooth');
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Gone, with the request still out.
    expect(find.text('New note'), findsNothing);
    expect(notes.created, isNull);

    gate.complete();
    await tester.pump();
    expect(notes.created?.personId, 'a1');
  });
}
