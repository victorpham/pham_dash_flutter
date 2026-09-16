import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/api/api_exception.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/core/ui/async_view.dart';
import 'package:pham_dash_flutter/data/models/todo_models.dart';
import 'package:pham_dash_flutter/data/repositories/todo_repository.dart';
import 'package:pham_dash_flutter/features/dashboard/dashboard_shell.dart';

const _chores = TodoLabel(id: 1, name: 'Chores', listCount: 1);

/// `TodoList` requires every collection and counter, so the fixtures go through
/// one helper rather than repeating six defaults apiece.
TodoList _list(
  int id,
  String title, {
  bool isPinned = false,
  bool isArchived = false,
  List<TodoLabel> labels = const [],
  int totalItems = 0,
  int completedItems = 0,
}) =>
    TodoList(
      id: id,
      title: title,
      isPinned: isPinned,
      isArchived: isArchived,
      displayOrder: id,
      items: const [],
      groups: const [],
      labels: labels,
      totalItems: totalItems,
      completedItems: completedItems,
    );

final _groceries =
    _list(10, 'Groceries', isPinned: true, totalItems: 6, completedItems: 1);
final _packing = _list(11, 'Packing', labels: const [_chores]);
final _oldTrip = _list(12, 'Last summer', isArchived: true);

/// Records what the tab asked for, so the archived toggle and the label chips
/// can be asserted at the endpoint rather than at the provider.
///
/// Subclasses rather than implements: `TodoRepository` holds a private
/// `ApiClient`, which another library cannot satisfy. Only the three reads the
/// tab performs are overridden, so the client is never touched.
class _FakeTodos extends TodoRepository {
  _FakeTodos(super.api);

  bool? lastIncludeArchived;
  int? lastLabelId;
  int listCalls = 0;

  /// When set, `lists()` waits on it - the cold-launch case, where the API is
  /// still waking the database.
  Completer<void>? gate;

  /// When set, `lists()` fails with it instead of answering.
  Object? failWith;

  @override
  Future<List<TodoList>> lists({bool includeArchived = false}) async {
    listCalls++;
    lastIncludeArchived = includeArchived;
    await gate?.future;
    final error = failWith;
    if (error != null) throw error;
    return includeArchived
        ? [_groceries, _packing, _oldTrip]
        : [_groceries, _packing];
  }

  @override
  Future<List<TodoLabel>> labels() async => const [_chores];

  @override
  Future<List<TodoList>> listsWithLabel(int labelId) async {
    lastLabelId = labelId;
    return [_packing];
  }
}

/// Pumps the tab the way `DashboardShell` builds it — through the enum hooks,
/// rather than by constructing `TodoListsTab` directly. The wiring is the part
/// that changed, and a `StatefulNavigationShell` is impractical to build here.
///
/// The cache store is swapped for an in-memory one, and no
/// `sharedPreferencesProvider` override is given: the tab reads nothing else
/// device-local, and that provider throws if read, so this doubles as an
/// assertion. [seed] pre-fills the store the way a previous launch would have.
Future<_FakeTodos> _pumpTab(
  WidgetTester tester, {
  Storage<String, String>? storage,
  Completer<void>? gate,
  Object? failWith,
  bool settle = true,
}) async {
  final todos = _FakeTodos(ApiClient(AuthService()))
    ..gate = gate
    ..failWith = failWith;

  await tester.pumpWidget(
    ProviderScope(
      // Riverpod 3 retries a failed provider on a backoff timer; the failure
      // cases count repository calls, so keep that out of the picture.
      retry: (_, _) => null,
      overrides: [
        todoRepositoryProvider.overrideWithValue(todos),
        cacheStorageProvider.overrideWithValue(storage ?? Storage.inMemory()),
      ],
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: Text(DashboardTab.lists.label),
            actions: DashboardTab.lists.appBarActions,
            bottom: DashboardTab.lists.appBarBottom,
          ),
          body: DashboardTab.lists.build(),
          floatingActionButton: DashboardTab.lists.floatingActionButton,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return todos;
}

/// A store holding what the previous launch saw: one list, not in the fake
/// repository's answer, so cached and fresh are distinguishable on screen.
Storage<String, String> _seededStore() {
  final store = Storage<String, String>.inMemory();
  store.write(
    'todo_lists',
    jsonEncode([_list(99, 'Saved last time').toJson()]),
    const StorageOptions(),
  );
  return store;
}

void main() {
  // The swap itself: the Lists tab used to be the scheduled "what's due now"
  // feed, which showed only lists due within minutes. It is the full browser
  // now, so an unscheduled list has to be visible.
  testWidgets('the Lists tab renders the list browser', (tester) async {
    await _pumpTab(tester);

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Packing'), findsOneWidget);
    expect(find.text('PINNED'), findsOneWidget);
    expect(find.text('ALL LISTS'), findsOneWidget);

    // The feed's sections are gone, not merely off screen.
    expect(find.text('Active'), findsNothing);
    expect(find.text('Up next'), findsNothing);
  });

  // The archived toggle and the filter bar are hosted by the shell's app bar
  // now, through DashboardTab. Asserting at the repository is what proves the
  // hook is wired to the provider rather than merely rendered.
  testWidgets('the archived toggle re-reads with archived included',
      (tester) async {
    final todos = await _pumpTab(tester);

    expect(todos.lastIncludeArchived, isFalse);
    expect(find.text('Last summer'), findsNothing);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.archive_outlined));
    await tester.pumpAndSettle();

    expect(todos.lastIncludeArchived, isTrue);
    expect(find.text('Last summer'), findsOneWidget);
  });

  testWidgets('a label chip narrows the directory', (tester) async {
    final todos = await _pumpTab(tester);

    expect(find.text('All'), findsOneWidget);
    await tester.tap(find.text('Chores (1)'));
    await tester.pumpAndSettle();

    expect(todos.lastLabelId, _chores.id);
    expect(find.text('Packing'), findsOneWidget);
    expect(find.text('Groceries'), findsNothing);
  });

  testWidgets('the tab carries a create button, the others do not',
      (tester) async {
    await _pumpTab(tester);

    expect(find.widgetWithIcon(FloatingActionButton, Icons.add), findsOneWidget);
    expect(DashboardTab.weather.floatingActionButton, isNull);
    expect(DashboardTab.weather.appBarActions, isEmpty);
    expect(DashboardTab.weather.appBarBottom, isNull);
  });

  // The cold-launch case the cache exists for: the API is still waking the
  // database, and the last answer is on screen under a progress bar instead
  // of a spinner. The fresh answer replaces it when it lands.
  testWidgets('a cached list shows at once and is replaced by the fetch',
      (tester) async {
    final gate = Completer<void>();
    await _pumpTab(tester, storage: _seededStore(), gate: gate, settle: false);
    await tester.pump();

    expect(find.text('Saved last time'), findsOneWidget);
    expect(find.byType(RefreshingStrip), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(PatientLoading.hint), findsNothing);

    // Past the delay the strip explains itself, as the spinner would have.
    await tester.pump(PatientLoading.hintAfter + const Duration(seconds: 1));
    expect(find.text(PatientLoading.hint), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Saved last time'), findsNothing);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.byType(RefreshingStrip), findsNothing);
  });

  // A failed refresh keeps what was on screen, says so, and can be retried
  // - the choice made over swapping the list for the error view.
  testWidgets('a failed refresh keeps the cached list under a banner',
      (tester) async {
    final todos = await _pumpTab(
      tester,
      storage: _seededStore(),
      failWith: const NetworkException('offline'),
    );

    expect(find.text('Saved last time'), findsOneWidget);
    expect(find.text(RefreshFailedBanner.title), findsOneWidget);
    expect(find.text('offline'), findsOneWidget);
    expect(find.byType(ErrorStateView), findsNothing);

    todos.failWith = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(todos.listCalls, 2);
    expect(find.text(RefreshFailedBanner.title), findsNothing);
    expect(find.text('Groceries'), findsOneWidget);
  });

  // The write-back half: what the fetch returned is what the next launch
  // will open to.
  testWidgets('a successful fetch is written to the cache', (tester) async {
    final store = Storage<String, String>.inMemory();
    await _pumpTab(tester, storage: store);

    final saved = await store.read('todo_lists');
    expect(saved, isNotNull);
    expect(saved!.data, contains('Groceries'));
    expect(saved.expireAt, isNotNull);
  });

  // Filters are in-memory and reset on launch, so a filtered answer must never
  // become the one the next launch opens to.
  testWidgets('a filtered view is not cached', (tester) async {
    final store = Storage<String, String>.inMemory();
    await _pumpTab(tester, storage: store);

    await tester.tap(find.text('Chores (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Packing'), findsOneWidget);

    final saved = await store.read('todo_lists');
    // Groceries is only in the default answer, so its presence proves the
    // filtered [Packing] result did not overwrite the store.
    expect(saved!.data, contains('Groceries'));
  });
}
