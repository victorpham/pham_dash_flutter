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
import 'package:pham_dash_flutter/features/todo/todo_item_image.dart';
import 'package:pham_dash_flutter/features/todo/todo_list_detail_screen.dart';

const _milk = TodoItem(
  id: 1,
  todoListId: 10,
  content: 'Milk',
  isCompleted: false,
  displayOrder: 0,
  indentLevel: 0,
  // Signed, the way the API hands it out. The query string is the credential.
  imageUrl: '/uploads/todo-items/1_20260915_ab.jpg?exp=1&sig=a',
  location: 'Aisle 3',
);

const _eggs = TodoItem(
  id: 2,
  todoListId: 10,
  content: 'Eggs',
  isCompleted: false,
  displayOrder: 1,
  indentLevel: 0,
);

const _bread = TodoItem(
  id: 3,
  todoListId: 10,
  groupId: 5,
  content: 'Bread',
  isCompleted: false,
  displayOrder: 2,
  indentLevel: 0,
);

const _bakery = TodoItemGroup(
  id: 5,
  todoListId: 10,
  name: 'Bakery',
  displayOrder: 0,
  items: [_bread],
);

const _groceries = TodoList(
  id: 10,
  title: 'Groceries',
  isPinned: false,
  isArchived: false,
  displayOrder: 0,
  items: [_milk, _eggs],
  groups: [_bakery],
  labels: [],
  totalItems: 3,
  completedItems: 0,
);

/// Subclasses rather than implements - see `todo_lists_tab_test.dart`. Records
/// the image writes so the sheet's actions can be asserted at the endpoint.
class _FakeTodos extends TodoRepository {
  _FakeTodos(super.api);

  final removed = <int>[];
  final updates = <(int, Map<String, dynamic>)>[];
  final added = <({String content, String? location})>[];
  final toggled = <int>[];

  /// When set, every read and write waits on it - the database asleep.
  Completer<void>? gate;

  /// When set, item writes fail with it after the gate.
  Object? failWritesWith;

  Future<void> _wait() async {
    await gate?.future;
  }

  Future<void> _write() async {
    await _wait();
    final error = failWritesWith;
    if (error != null) throw error;
  }

  /// What the server holds. Writes change it, so the re-read that follows
  /// a successful write sees what a real server would show.
  TodoList server = _groceries;

  void _replace(TodoItem item) {
    server = server.copyWith(
      items: [
        for (final i in server.items)
          if (i.id == item.id) item else i,
      ],
    );
  }

  @override
  Future<TodoList?> list(int id) async {
    await _wait();
    return server;
  }

  @override
  Future<TodoItem?> toggleItem(int itemId) async {
    await _write();
    toggled.add(itemId);
    final item = server.allItems.firstWhere((i) => i.id == itemId);
    final flipped = item.copyWith(isCompleted: !item.isCompleted);
    _replace(flipped);
    return flipped;
  }

  @override
  Future<void> deleteItem(int itemId) async {
    await _write();
    server = server.copyWith(
      items: server.items.where((i) => i.id != itemId).toList(),
    );
  }

  @override
  Future<void> removeItemImage(int itemId) async => removed.add(itemId);

  @override
  Future<TodoItem?> addItem(
    int listId, {
    required String content,
    int? indentLevel,
    int? groupId,
    String? location,
  }) async {
    await _write();
    added.add((content: content, location: location));
    final created = TodoItem(
      id: 100 + added.length,
      todoListId: listId,
      content: content,
      location: location,
      isCompleted: false,
      displayOrder: 99,
      indentLevel: 0,
    );
    server = server.copyWith(items: [...server.items, created]);
    return created;
  }

  @override
  Future<TodoItem?> updateItem(int itemId, UpdateTodoItem body) async {
    await _write();
    updates.add((itemId, body.toJson()));
    return null;
  }
}

/// The Lists tab's cache as a previous launch would have left it: the same
/// list, so the detail screen has something to show before its own fetch.
Storage<String, String> _seededStore() {
  final store = Storage<String, String>.inMemory();
  store.write(
    'todo_lists',
    jsonEncode([_groceries.toJson()]),
    const StorageOptions(),
  );
  return store;
}

Future<_FakeTodos> _pump(
  WidgetTester tester, {
  Storage<String, String>? storage,
  Completer<void>? gate,
  Object? failWritesWith,
  bool settle = true,
}) async {
  final todos = _FakeTodos(ApiClient(AuthService()))
    ..gate = gate
    ..failWritesWith = failWritesWith;

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        todoRepositoryProvider.overrideWithValue(todos),
        cacheStorageProvider.overrideWithValue(storage ?? Storage.inMemory()),
      ],
      child: const MaterialApp(home: TodoListDetailScreen(listId: 10)),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return todos;
}

void main() {
  _optimisticTests();
  _viewerTests();
  _locationAndGroupTests();

  // CachedNetworkImage never gets to fetch anything under test, so the
  // assertions are on the thumbnail's wrapper key rather than on pixels.
  testWidgets('an item with a picture shows a thumbnail; one without does not',
      (tester) async {
    await _pump(tester);

    expect(find.byKey(const ValueKey('item-image-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('item-image-2')), findsNothing);
  });

  testWidgets('long-press offers Remove photo only when there is one',
      (tester) async {
    await _pump(tester);

    await tester.longPress(find.text('Eggs'));
    await tester.pumpAndSettle();
    expect(find.text('Edit item…'), findsOneWidget);
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Remove photo'), findsNothing);

    // Dismiss the sheet.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Milk'));
    await tester.pumpAndSettle();
    expect(find.text('Remove photo'), findsOneWidget);
  });

  testWidgets('Remove photo confirms, then calls the endpoint', (tester) async {
    final todos = await _pump(tester);

    await tester.longPress(find.text('Milk'));
    await tester.pumpAndSettle();
    // Last entry on a sheet that now scrolls on a short screen.
    await tester.ensureVisible(find.text('Remove photo'));
    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();

    expect(find.text('Remove this photo?'), findsOneWidget);
    expect(todos.removed, isEmpty);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(todos.removed, [1]);
  });
}

void _viewerTests() {
  Future<void> pumpViewer(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTodoItemImage(context, _milk),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // Two frames, not pumpAndSettle: the route needs one to push and one to
    // build, and the loading spinner would keep pumpAndSettle waiting forever.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(TodoItemImageViewer), findsOneWidget);
  }

  testWidgets('tapping the backdrop closes the viewer', (tester) async {
    await pumpViewer(tester);

    // Bottom corner: well outside any centred image.
    final backdrop = find.byKey(const ValueKey('item-image-backdrop'));
    await tester.tapAt(tester.getBottomLeft(backdrop) + const Offset(8, -8));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(TodoItemImageViewer), findsNothing);
  });

  testWidgets('tapping the image itself does not close the viewer',
      (tester) async {
    await pumpViewer(tester);

    // The InteractiveViewer is sized to whatever the image slot shows - under
    // test, the placeholder or the broken-image icon - so its centre is "on
    // the image" either way.
    await tester.tap(find.byType(InteractiveViewer));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(TodoItemImageViewer), findsOneWidget);
  });
}

void _locationAndGroupTests() {
  testWidgets('an item with a location shows it under the text',
      (tester) async {
    await _pump(tester);

    expect(find.byKey(const ValueKey('item-location-1')), findsOneWidget);
    expect(find.text('Aisle 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('item-location-2')), findsNothing);
  });

  testWidgets('Edit item… opens both fields prefilled and clears with ""',
      (tester) async {
    final todos = await _pump(tester);

    await tester.longPress(find.text('Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit item…'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Milk'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Aisle 3'), findsOneWidget);

    // Emptying the location must reach the API as "", not be dropped.
    await tester.enterText(find.widgetWithText(TextField, 'Aisle 3'), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(todos.updates.single.$1, 1);
    expect(todos.updates.single.$2, {'content': 'Milk', 'location': ''});
  });

  testWidgets('Add item sends the location only when one was typed',
      (tester) async {
    final todos = await _pump(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Item'), 'Butter');
    await tester.enterText(
      find.widgetWithText(TextField, 'Location (optional)'),
      '  Dairy ',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(todos.added, [(content: 'Butter', location: 'Dairy')]);
  });

  testWidgets('Move to group… offers the groups and sends the chosen id',
      (tester) async {
    final todos = await _pump(tester);

    await tester.longPress(find.text('Eggs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to group…'));
    await tester.pumpAndSettle();

    expect(find.text('(No group)'), findsOneWidget);
    await tester.tap(find.widgetWithText(SimpleDialogOption, 'Bakery'));
    await tester.pumpAndSettle();

    expect(todos.updates.single.$1, 2);
    expect(todos.updates.single.$2, {'groupId': 5});
  });

  testWidgets('Move to group… on a grouped item can send it back to no group',
      (tester) async {
    final todos = await _pump(tester);

    await tester.longPress(find.text('Bread'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to group…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('(No group)'));
    await tester.pumpAndSettle();

    expect(todos.updates.single.$1, 3);
    expect(todos.updates.single.$2, {'groupId': 0});
  });
}

/// The point of the notifier: the shopping list works while the database is
/// asleep. Every read and write here is gated behind a completer that stands
/// in for the wake, and the assertions are made before it completes.
void _optimisticTests() {
  // Nothing in the fixture starts completed, so "a checked row" is "the
  // checked icon exists".
  Finder checked(String _) => find.byIcon(Icons.check_circle);

  testWidgets('a list opens from the Lists cache before its own fetch lands',
      (tester) async {
    final gate = Completer<void>();
    await _pump(tester, storage: _seededStore(), gate: gate, settle: false);
    await tester.pump();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.byType(RefreshingStrip), findsOneWidget);
    expect(find.byType(PatientLoading), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(RefreshingStrip), findsNothing);
  });

  testWidgets('toggling flips the row at once, before the server answers',
      (tester) async {
    final gate = Completer<void>();
    // Cold launch: the detail fetch is still pending when the tap happens, so
    // the notifier has to work from the cached copy.
    final todos =
        await _pump(tester, storage: _seededStore(), gate: gate, settle: false);
    await tester.pump();
    expect(checked('Milk'), findsNothing);

    await tester.tap(find.text('Milk'));
    await tester.pump();
    // Two frames: the first swaps the screen from the cached fallback to the
    // patched list, the second settles the rows.
    await tester.pump();

    expect(checked('Milk'), findsOneWidget);
    expect(todos.toggled, isEmpty, reason: 'the server has not answered yet');

    gate.complete();
    await tester.pumpAndSettle();
    expect(todos.toggled, [1]);
    expect(checked('Milk'), findsOneWidget);
  });

  testWidgets('a failed toggle rolls the row back and says so',
      (tester) async {
    final gate = Completer<void>();
    final todos = await _pump(tester);
    todos.gate = gate;

    await tester.tap(find.text('Milk'));
    await tester.pump();
    await tester.pump();
    expect(checked('Milk'), findsOneWidget);

    // The server answers - with a failure.
    todos.failWritesWith = const NetworkException('Server asleep');
    gate.complete();
    await tester.pumpAndSettle();
    expect(checked('Milk'), findsNothing);
    expect(find.text('Server asleep'), findsOneWidget);
  });

  testWidgets("adding shows a placeholder, then the server's item",
      (tester) async {
    final gate = Completer<void>();
    final todos = await _pump(tester);
    todos.gate = gate;

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Item'), 'Butter');
    await tester.tap(find.text('Save'));
    // Timed, not settled: the app-bar sync spinner runs while the write is
    // gated. Enough frames for the dialog to leave.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // On screen already, but not actionable: no long-press sheet.
    expect(find.text('Butter'), findsOneWidget);
    await tester.longPress(find.text('Butter'));
    await tester.pump();
    expect(find.text('Edit item…'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Butter'), findsOneWidget);
    await tester.longPress(find.text('Butter'));
    await tester.pumpAndSettle();
    expect(find.text('Edit item…'), findsOneWidget);
  });

  testWidgets('deleting removes the row at once', (tester) async {
    final gate = Completer<void>();
    final todos = await _pump(tester);
    todos.gate = gate;

    await tester.drag(find.text('Eggs'), const Offset(-600, 0));
    // The dismiss animates, then onDismissed patches the list: a few frames,
    // pumped by hand because the sync spinner keeps pumpAndSettle waiting.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Eggs'), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Eggs'), findsNothing);
  });
}
