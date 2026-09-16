import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/data/repositories/people_repository.dart';
import 'package:pham_dash_flutter/features/people/people_providers.dart';
import 'package:pham_dash_flutter/features/people/person_edit_sheet.dart';

/// A tall-ish phone, and a keyboard covering the bottom 340 of it.
const double _screenHeight = 800;
const double _keyboardHeight = 340;
const double _aboveKeyboard = _screenHeight - _keyboardHeight;

/// Opens the sheet the way the people screen does — through
/// [showPersonEditSheet], since the modal route is what is under test here.
/// Pumping [PersonEditSheet] directly, as the tag tests do, would skip it.
Future<void> _openCreateSheet(WidgetTester tester) async {
  addTearDown(tester.view.reset);
  tester.view.physicalSize = const Size(400, _screenHeight);
  tester.view.devicePixelRatio = 1;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        allPeopleProvider.overrideWithBuild((ref, _) => const <Person>[]),
        personTagsProvider.overrideWithBuild((ref, _) => const <PersonTag>[]),
        peopleRepositoryProvider.overrideWithValue(
          PeopleRepository(ApiClient(AuthService())),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPersonEditSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void _raiseKeyboard(WidgetTester tester) {
  tester.view.viewInsets = const FakeViewPadding(bottom: _keyboardHeight);
}

void main() {
  // The regression this file exists for: the sheet used to be sized to its
  // content and sit at the bottom of the screen, and the create path
  // autofocuses the first name field - so the keyboard came up over the lower
  // half of the form, the save button included, with no way to scroll it clear.
  testWidgets('no part of the form sits under the keyboard', (tester) async {
    await _openCreateSheet(tester);

    _raiseKeyboard(tester);
    await tester.pumpAndSettle();

    final form = tester.getRect(find.byType(SingleChildScrollView));
    expect(form.bottom, lessThanOrEqualTo(_aboveKeyboard));
    expect(tester.takeException(), isNull);
  });

  // Anchoring is only half of it: the space the keyboard leaves has to be
  // scrollable, or the fields below the fold are still unreachable.
  testWidgets('the save button can be scrolled to with the keyboard up',
      (tester) async {
    await _openCreateSheet(tester);

    _raiseKeyboard(tester);
    await tester.pumpAndSettle();

    final save = find.widgetWithText(FilledButton, 'Add person');
    await tester.dragUntilVisible(
      save,
      find.byType(SingleChildScrollView),
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();

    expect(tester.getRect(save).bottom, lessThanOrEqualTo(_aboveKeyboard));
  });

  // Without a keyboard the sheet still reaches the top, which is the part of
  // the fix that is a deliberate look rather than a bug fix.
  testWidgets('the sheet is full height before the keyboard opens',
      (tester) async {
    await _openCreateSheet(tester);

    final form = tester.getRect(find.byType(SingleChildScrollView));
    expect(form.bottom, closeTo(_screenHeight, 1));
    expect(form.top, lessThan(100));
  });
}
