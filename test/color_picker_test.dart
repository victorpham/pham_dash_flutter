import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/ui/color_picker_sheet.dart';

/// Opens the picker and hands back whatever it returns.
///
/// The result is captured through a holder because the future completes when
/// the dialog pops, long after the tap that opened it.
class _Result {
  String? value;
  bool returned = false;
}

Future<_Result> _openPicker(WidgetTester tester, {String? initial}) async {
  final result = _Result();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result.value = await showColorPicker(context, initial: initial);
              result.returned = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

Finder _hexField() => find.widgetWithText(TextField, 'Hex');

void main() {
  testWidgets('opens on the current colour', (tester) async {
    await _openPicker(tester, initial: '#ff0000');

    // The preview prints the hex, so it doubles as the assertion.
    expect(find.text('#ff0000'), findsOneWidget);
  });

  testWidgets('a typed hex becomes the picked colour', (tester) async {
    final result = await _openPicker(tester, initial: '#ff0000');

    await tester.enterText(_hexField(), '00ff7f');
    await tester.pumpAndSettle();
    expect(find.text('#00ff7f'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Use colour'));
    await tester.pumpAndSettle();

    expect(result.value, '#00ff7f');
  });

  // Half-typed input must not throw or reset the preview — the field is parsed
  // on every keystroke.
  testWidgets('a partial hex is ignored rather than fought', (tester) async {
    await _openPicker(tester, initial: '#ff0000');

    await tester.enterText(_hexField(), '00f');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('#ff0000'), findsOneWidget);
  });

  testWidgets('cancelling picks nothing', (tester) async {
    final result = await _openPicker(tester, initial: '#ff0000');

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(result.returned, isTrue);
    expect(result.value, isNull);
  });

  testWidgets('dragging a slider changes the colour', (tester) async {
    final result = await _openPicker(tester, initial: '#ff0000');

    // The hue slider is the first of the three.
    await tester.drag(find.byType(Slider).first, const Offset(60, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Use colour'));
    await tester.pumpAndSettle();

    expect(result.value, isNot('#ff0000'));
    expect(result.value, matches(RegExp(r'^#[0-9a-f]{6}$')));
  });

  testWidgets('with no colour yet it still opens', (tester) async {
    await _openPicker(tester);

    expect(find.text('Custom colour'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(3));
  });
}
