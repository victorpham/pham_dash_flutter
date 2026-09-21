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

  testWidgets('failed writes turn the glyph red, and a tap calls back', (
    tester,
  ) async {
    late ProviderContainer container;
    var taps = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              home: Scaffold(
                body: SyncIndicator(onFailedTap: () => taps++),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    container.read(pendingWritesProvider.notifier).setFailed(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('sync-failed')), findsOneWidget);
    expect(find.byTooltip('2 changes couldn’t be saved'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sync-failed')));
    expect(taps, 1);

    // In flight outranks failed: the spinner is what shows while a retry is
    // out, and the red glyph comes back only if it fails again.
    final gate = Completer<void>();
    final write = container
        .read(pendingWritesProvider.notifier)
        .track(() => gate.future);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const ValueKey('sync-in-flight')), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-failed')), findsNothing);

    container.read(pendingWritesProvider.notifier).setFailed(0);
    gate.complete();
    await write;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const ValueKey('sync-failed')), findsNothing);
    expect(find.byKey(const ValueKey('sync-confirmed')), findsOneWidget);
  });
}
