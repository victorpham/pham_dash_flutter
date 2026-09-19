import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_exception.dart';
import 'package:pham_dash_flutter/core/ui/async_view.dart';

/// `fallback` is how a screen shows a record it already holds elsewhere (the
/// lists cache, the directory) while its own provider has nothing yet. It has
/// to look exactly like a cached seed - strip while loading, banner on error -
/// and step aside the moment the provider has a value of its own.
void main() {
  Widget host(AsyncValue<String> value, {String? fallback}) => MaterialApp(
        home: Scaffold(
          body: AsyncView<String>(
            value: value,
            fallback: fallback,
            builder: (data) => Text('shown: $data'),
          ),
        ),
      );

  testWidgets('loading with a fallback renders it under the strip',
      (tester) async {
    await tester.pumpWidget(
      host(const AsyncLoading(), fallback: 'cached'),
    );
    await tester.pump();

    expect(find.text('shown: cached'), findsOneWidget);
    expect(find.byType(RefreshingStrip), findsOneWidget);
    expect(find.byType(PatientLoading), findsNothing);
  });

  testWidgets('an error with a fallback renders it under the banner',
      (tester) async {
    await tester.pumpWidget(
      host(
        AsyncError(const NetworkException('Offline'), StackTrace.empty),
        fallback: 'cached',
      ),
    );
    await tester.pump();

    expect(find.text('shown: cached'), findsOneWidget);
    expect(find.byType(RefreshFailedBanner), findsOneWidget);
    expect(find.byType(ErrorStateView), findsNothing);
  });

  testWidgets('a value of its own wins over the fallback', (tester) async {
    await tester.pumpWidget(
      host(const AsyncData('fresh'), fallback: 'cached'),
    );
    await tester.pump();

    expect(find.text('shown: fresh'), findsOneWidget);
    expect(find.text('shown: cached'), findsNothing);
    expect(find.byType(RefreshingStrip), findsNothing);
  });

  testWidgets('without a fallback, loading is the spinner as before',
      (tester) async {
    await tester.pumpWidget(host(const AsyncLoading()));
    await tester.pump();

    expect(find.byType(PatientLoading), findsOneWidget);
  });
}
