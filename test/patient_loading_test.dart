import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/ui/async_view.dart';

Future<void> _pump(WidgetTester tester, {bool explainSlowLoad = true}) =>
    tester.pumpWidget(
      MaterialApp(
        home: AsyncView<List<int>>(
          value: const AsyncLoading(),
          explainSlowLoad: explainSlowLoad,
          builder: (_) => const SizedBox(),
        ),
      ),
    );

void main() {
  // A serverless database resume looks exactly like a hang from the phone,
  // so the spinner explains itself - but only once the wait is past what a
  // normal load takes, or every screen would flash the message.
  testWidgets('the wake-up hint appears only after the delay', (tester) async {
    await _pump(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(PatientLoading.hint), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text(PatientLoading.hint), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text(PatientLoading.hint), findsOneWidget);
    expect(find.text(PatientLoading.detail), findsOneWidget);
  });

  // Weather never reaches the API, so a slow forecast must not blame a
  // database it never touched.
  testWidgets('a screen can opt out of the hint', (tester) async {
    await _pump(tester, explainSlowLoad: false);

    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(PatientLoading.hint), findsNothing);
  });

  // Data arriving disposes the spinner and its timer with it - a hint that
  // fired onto a loaded screen would be the setState-after-dispose bug.
  testWidgets('data arriving before the delay cancels the hint',
      (tester) async {
    await _pump(tester);
    await tester.pump(const Duration(seconds: 3));

    await tester.pumpWidget(
      MaterialApp(
        home: AsyncView<List<int>>(
          value: const AsyncData([1]),
          builder: (data) => Text('loaded ${data.length}'),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 10));

    expect(find.text('loaded 1'), findsOneWidget);
    expect(find.text(PatientLoading.hint), findsNothing);
  });
}
