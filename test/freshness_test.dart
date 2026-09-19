import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/core/cache/freshness.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/core/ui/freshness_caption.dart';
import 'package:pham_dash_flutter/data/models/todo_models.dart';
import 'package:pham_dash_flutter/data/repositories/todo_repository.dart';
import 'package:pham_dash_flutter/features/todo/todo_providers.dart';

class _FakeTodos extends TodoRepository {
  _FakeTodos(super.api);

  Completer<void>? gate;

  @override
  Future<List<TodoLabel>> labels() async {
    await gate?.future;
    return const [TodoLabel(id: 1, name: 'Chores', listCount: 0)];
  }
}

void main() {
  group('formatFreshness', () {
    final now = DateTime(2026, 9, 19, 10, 42);

    test('reads naturally at every distance', () {
      expect(formatFreshness(now, now), 'just now');
      expect(
        formatFreshness(now.subtract(const Duration(minutes: 3)), now),
        '3 min ago',
      );
      expect(formatFreshness(DateTime(2026, 9, 19, 8, 5), now), 'at 08:05');
      expect(
        formatFreshness(DateTime(2026, 9, 18, 18, 2), now),
        'yesterday 18:02',
      );
      expect(
        formatFreshness(DateTime(2026, 9, 12, 18, 2), now),
        'Sep 12 18:02',
      );
    });
  });

  group('recordFetch through a CachedList notifier', () {
    test(
      'stamps the key when a fetch completes, not when the cache seeds',
      () async {
        final store = Storage<String, String>.inMemory();
        store.write(
          'todo_labels',
          '[{"id":1,"name":"Chores","listCount":0}]',
          const StorageOptions(),
        );
        final gate = Completer<void>();
        final container = ProviderContainer(
          overrides: [
            todoRepositoryProvider.overrideWithValue(
              _FakeTodos(ApiClient(AuthService()))..gate = gate,
            ),
            cacheStorageProvider.overrideWithValue(store),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(todoLabelsProvider, (_, _) {});
        addTearDown(sub.close);
        await Future<void>.delayed(Duration.zero);

        // Seeded from cache: showing data, but nothing has been confirmed.
        expect(container.read(todoLabelsProvider).hasValue, isTrue);
        expect(container.read(freshnessProvider)['todo_labels'], isNull);

        gate.complete();
        await container.read(todoLabelsProvider.future);
        await Future<void>.delayed(Duration.zero);

        final stamp = container.read(freshnessProvider)['todo_labels'];
        expect(stamp, isNotNull);
        expect(DateTime.now().difference(stamp!).inSeconds, lessThan(5));

        // And it was written through, so the next launch reads it back.
        final persisted = store.read(FreshnessNotifier.storageKey);
        expect(persisted, isNotNull);
      },
    );
  });

  testWidgets('FreshnessCaption turns into a warning past an hour', (
    tester,
  ) async {
    Future<void> pumpAt(DateTime at) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FreshnessCaption(updatedAt: at)),
        ),
      );
      await tester.pump();
    }

    await pumpAt(DateTime.now().subtract(const Duration(minutes: 2)));
    expect(find.text('Updated 2 min ago'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

    await pumpAt(DateTime.now().subtract(const Duration(hours: 3)));
    expect(find.byIcon(Icons.history), findsOneWidget);
  });

  testWidgets('a null stamp renders nothing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FreshnessCaption(updatedAt: null)),
      ),
    );
    expect(find.byKey(const ValueKey('freshness-caption')), findsNothing);
  });
}
