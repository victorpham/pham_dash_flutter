import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/sync/pending_writes.dart';
import 'package:pham_dash_flutter/core/ui/sync_indicator.dart';

void main() {
  testWidgets(
    'spins while a write is in flight, checks when it lands, then goes',
    (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: Scaffold(appBar: null, body: SyncIndicator()),
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('sync-in-flight')), findsNothing);
      expect(find.byKey(const ValueKey('sync-confirmed')), findsNothing);

      final gate = Completer<void>();
      final write = container
          .read(pendingWritesProvider.notifier)
          .track(() => gate.future);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const ValueKey('sync-in-flight')), findsOneWidget);

      gate.complete();
      await write;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const ValueKey('sync-in-flight')), findsNothing);
      expect(find.byKey(const ValueKey('sync-confirmed')), findsOneWidget);

      await tester.pump(
        SyncIndicator.confirmedFor + const Duration(seconds: 1),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const ValueKey('sync-confirmed')), findsNothing);
    },
  );

  testWidgets('a failed write clears the spinner without a check', (
    tester,
  ) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const MaterialApp(home: Scaffold(body: SyncIndicator()));
          },
        ),
      ),
    );
    await tester.pump();

    final write = container
        .read(pendingWritesProvider.notifier)
        .track<void>(() => Future.error(StateError('nope')));
    await expectLater(write, throwsStateError);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('sync-in-flight')), findsNothing);
    expect(find.byKey(const ValueKey('sync-confirmed')), findsNothing);
  });
}
